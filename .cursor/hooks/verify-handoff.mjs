#!/usr/bin/env node
/**
 * Handoff gate: after code edits, require a production build when the project
 * has one; otherwise the usual fallback gate. On stop, auto-continue until
 * that gate ran successfully this conversation.
 *
 * State lives under ~/.cursor/hooks-state/ (not inside the linked hooks dir).
 */
import { createHash } from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { stdin } from "node:process";

const STATE_DIR = path.join(os.homedir(), ".cursor", "hooks-state", "verify-handoff");

const CODE_EXTS = new Set([
  ".ts",
  ".tsx",
  ".js",
  ".jsx",
  ".mjs",
  ".cjs",
  ".py",
  ".rs",
  ".go",
  ".java",
  ".kt",
  ".swift",
  ".css",
  ".scss",
  ".sass",
  ".less",
  ".vue",
  ".svelte",
  ".astro",
  ".json",
  ".toml",
  ".yml",
  ".yaml",
  ".sql",
  ".html",
  ".htm",
  ".sh",
  ".bash",
  ".zsh",
  ".rb",
  ".php",
  ".cs",
  ".cpp",
  ".cc",
  ".cxx",
  ".c",
  ".h",
  ".hpp",
  ".hxx",
]);

const FALLBACK_SCRIPT_NAMES = ["typecheck", "lint", "test", "check", "ci"];

function readStdin() {
  return new Promise((resolve, reject) => {
    const chunks = [];
    stdin.on("data", (c) => chunks.push(c));
    stdin.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
    stdin.on("error", reject);
  });
}

function reply(obj) {
  process.stdout.write(JSON.stringify(obj) + "\n");
}

function ensureStateDir() {
  fs.mkdirSync(STATE_DIR, { recursive: true });
}

function statePath(conversationId) {
  const safe = createHash("sha256").update(conversationId).digest("hex").slice(0, 24);
  return path.join(STATE_DIR, `${safe}.json`);
}

function loadState(conversationId) {
  ensureStateDir();
  const p = statePath(conversationId);
  try {
    return JSON.parse(fs.readFileSync(p, "utf8"));
  } catch {
    return { pending: [], satisfied: [] };
  }
}

function saveState(conversationId, state) {
  ensureStateDir();
  fs.writeFileSync(statePath(conversationId), JSON.stringify(state, null, 2));
}

function isCodePath(filePath) {
  const base = path.basename(filePath);
  if (base === "Dockerfile" || base.startsWith("Dockerfile.")) return true;
  return CODE_EXTS.has(path.extname(filePath).toLowerCase());
}

function packageManager(dir) {
  if (fs.existsSync(path.join(dir, "pnpm-lock.yaml"))) return "pnpm";
  if (fs.existsSync(path.join(dir, "yarn.lock"))) return "yarn";
  if (fs.existsSync(path.join(dir, "bun.lockb")) || fs.existsSync(path.join(dir, "bun.lock"))) {
    return "bun";
  }
  return "npm";
}

function runScript(pm, script) {
  if (pm === "yarn") return `yarn ${script}`;
  if (pm === "bun") return `bun run ${script}`;
  if (pm === "pnpm") return `pnpm run ${script}`;
  return `npm run ${script}`;
}

function nodeGate(dir) {
  let pkg;
  try {
    pkg = JSON.parse(fs.readFileSync(path.join(dir, "package.json"), "utf8"));
  } catch {
    return null;
  }
  const scripts = pkg.scripts || {};
  const pm = packageManager(dir);
  if (scripts.build) {
    return {
      id: `${dir}::build`,
      kind: "build",
      dir,
      command: runScript(pm, "build"),
      label: "production build",
    };
  }
  for (const name of FALLBACK_SCRIPT_NAMES) {
    if (scripts[name]) {
      return {
        id: `${dir}::fallback:${name}`,
        kind: "fallback",
        dir,
        command: runScript(pm, name),
        label: `usual gate (${name}; no build script)`,
      };
    }
  }
  if (fs.existsSync(path.join(dir, "tsconfig.json"))) {
    return {
      id: `${dir}::fallback:tsc`,
      kind: "fallback",
      dir,
      command: "npx tsc --noEmit",
      label: "usual gate (tsc --noEmit; no build script)",
    };
  }
  return null;
}

function rustGate(dir) {
  return {
    id: `${dir}::build`,
    kind: "build",
    dir,
    command: "cargo build",
    label: "production build",
  };
}

function goGate(dir) {
  return {
    id: `${dir}::build`,
    kind: "build",
    dir,
    command: "go build ./...",
    label: "production build",
  };
}

function findGateForFile(filePath) {
  let dir = path.dirname(filePath);
  for (;;) {
    if (fs.existsSync(path.join(dir, "package.json"))) return nodeGate(dir);
    if (fs.existsSync(path.join(dir, "Cargo.toml"))) return rustGate(dir);
    if (fs.existsSync(path.join(dir, "go.mod"))) return goGate(dir);
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

function normalizeCmd(cmd) {
  return String(cmd || "")
    .replace(/\s+/g, " ")
    .trim();
}

function commandSatisfies(command, gate) {
  const cmd = normalizeCmd(command);
  if (!cmd) return false;

  if (gate.kind === "build") {
    if (/\b(npm|pnpm|yarn|bun)(\s+run)?\s+build\b/.test(cmd)) return true;
    if (/\bcargo\s+build\b/.test(cmd)) return true;
    if (/\bgo\s+build\b/.test(cmd)) return true;
    if (/\bdotnet\s+build\b/.test(cmd)) return true;
  }

  const wanted = normalizeCmd(gate.command);
  if (wanted && cmd.includes(wanted)) return true;

  // Fallback script name match inside the project dir context
  if (gate.kind === "fallback") {
    const m = wanted.match(/\b(typecheck|lint|test|check|ci)\b/);
    if (m && new RegExp(`\\b(npm|pnpm|yarn|bun)(\\s+run)?\\s+${m[1]}\\b`).test(cmd)) {
      return true;
    }
    if (/tsc\s+--noEmit/.test(wanted) && /tsc\s+--noEmit/.test(cmd)) return true;
  }

  return false;
}

function parseExitCode(toolOutput) {
  if (toolOutput == null) return null;
  if (typeof toolOutput === "number") return toolOutput;
  try {
    const parsed = typeof toolOutput === "string" ? JSON.parse(toolOutput) : toolOutput;
    if (typeof parsed?.exitCode === "number") return parsed.exitCode;
    if (typeof parsed?.exit_code === "number") return parsed.exit_code;
  } catch {
    // ignore
  }
  return null;
}

function upsertPending(state, gate) {
  if (!gate) return;
  state.pending = state.pending || [];
  state.satisfied = state.satisfied || [];
  if (state.satisfied.includes(gate.id)) return;
  if (!state.pending.some((g) => g.id === gate.id)) {
    state.pending.push(gate);
  }
}

function markSatisfied(state, gateId) {
  state.pending = (state.pending || []).filter((g) => g.id !== gateId);
  state.satisfied = state.satisfied || [];
  if (!state.satisfied.includes(gateId)) state.satisfied.push(gateId);
}

function handleAfterFileEdit(payload) {
  const filePath = payload.file_path;
  if (!filePath || !isCodePath(filePath)) {
    reply({});
    return;
  }
  const conversationId = payload.conversation_id;
  if (!conversationId) {
    reply({});
    return;
  }
  const gate = findGateForFile(filePath);
  if (!gate) {
    reply({});
    return;
  }
  const state = loadState(conversationId);
  upsertPending(state, gate);
  saveState(conversationId, state);
  reply({});
}

function handlePostToolUse(payload) {
  const toolName = payload.tool_name || "";
  if (!/shell/i.test(toolName)) {
    reply({});
    return;
  }
  const conversationId = payload.conversation_id;
  if (!conversationId) {
    reply({});
    return;
  }

  const input = payload.tool_input || {};
  const command = typeof input === "string" ? input : input.command || "";
  const exitCode = parseExitCode(payload.tool_output);
  if (exitCode !== 0 && exitCode !== null) {
    reply({});
    return;
  }
  // Missing exit code: still accept if command looks like the gate (fail open on parse)

  const state = loadState(conversationId);
  const pending = state.pending || [];
  let changed = false;
  for (const gate of [...pending]) {
    if (commandSatisfies(command, gate)) {
      markSatisfied(state, gate.id);
      changed = true;
    }
  }
  if (changed) saveState(conversationId, state);
  reply({});
}

function handleStop(payload) {
  if (payload.status && payload.status !== "completed") {
    reply({});
    return;
  }
  const conversationId = payload.conversation_id;
  if (!conversationId) {
    reply({});
    return;
  }
  const state = loadState(conversationId);
  const pending = state.pending || [];
  if (pending.length === 0) {
    reply({});
    return;
  }

  const lines = pending.map(
    (g) => `- ${g.label}: \`${g.command}\` (in ${g.dir})`
  );

  const followup_message = [
    "Handoff gate missing. This turn edited code but the required build/gate did not run successfully.",
    "",
    "Run these now (typecheck/unit tests alone do not replace a production build when one exists):",
    ...lines,
    "",
    "Fix failures, then stop again. If a listed package truly has no build and the fallback already passed, say so.",
  ].join("\n");

  reply({ followup_message });
}

async function main() {
  const raw = await readStdin();
  if (!raw.trim()) {
    reply({});
    return;
  }
  const payload = JSON.parse(raw);
  const event = payload.hook_event_name || "";

  if (event === "afterFileEdit") {
    handleAfterFileEdit(payload);
    return;
  }
  if (event === "postToolUse") {
    handlePostToolUse(payload);
    return;
  }
  if (event === "stop") {
    handleStop(payload);
    return;
  }

  // Invoked without event name: try positional mode for local tests
  const mode = process.argv[2];
  if (mode === "afterFileEdit") handleAfterFileEdit(payload);
  else if (mode === "postToolUse") handlePostToolUse(payload);
  else if (mode === "stop") handleStop(payload);
  else reply({});
}

main().catch((err) => {
  console.error("[verify-handoff]", err);
  reply({});
});
