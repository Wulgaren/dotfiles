import { Plugin } from "@opencode/plugin"
import { spawn } from "node:child_process"

// Same guard the Claude plugin and the Cursor hook call. It owns the read
// policy; this file only translates OpenCode's tool events into its protocol.
const SCRIPT = `${process.env.HOME ?? ""}/.claude/local-marketplace/plugins/grunt/scripts/guard-read`

// Windows cannot start an extensionless shebang script directly, so route the
// guard through Git Bash there. GRUNT_BASH overrides a non-default install.
const BASH =
  process.platform === "win32" ? (process.env.GRUNT_BASH ?? "C:/Program Files/Git/bin/bash.exe") : undefined

type GuardResult = {
  code: number
  stdout: string
  stderr: string
}

function guard(toolName: string, toolInput: Record<string, unknown>): Promise<GuardResult> {
  return new Promise((resolve) => {
    const child =
      BASH === undefined
        ? spawn(SCRIPT, { stdio: ["pipe", "pipe", "pipe"] })
        : spawn(BASH, [SCRIPT], { stdio: ["pipe", "pipe", "pipe"] })
    let stdout = ""
    let stderr = ""

    child.stdout.setEncoding("utf8").on("data", (chunk: string) => {
      stdout += chunk
    })
    child.stderr.setEncoding("utf8").on("data", (chunk: string) => {
      stderr += chunk
    })
    child.on("error", () => resolve({ code: 0, stdout: "", stderr: "" }))
    child.on("close", (code) => resolve({ code: code ?? 0, stdout, stderr }))
    child.stdin.end(JSON.stringify({ tool_name: toolName, tool_input: toolInput }))
  })
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null
}

function fieldValue(input: unknown, key: string): unknown {
  return isRecord(input) ? input[key] : undefined
}

function stringField(input: unknown, key: string): string | undefined {
  const value = fieldValue(input, key)
  return typeof value === "string" ? value : undefined
}

function numberField(input: unknown, key: string): number | undefined {
  const value = fieldValue(input, key)
  return typeof value === "number" ? value : undefined
}

// The guard allows a capped shell command with Claude's nested
// hookSpecificOutput.updatedInput. Pull the rewritten command out of it.
function rewrittenCommand(stdout: string): string | undefined {
  if (!stdout.trimStart().startsWith("{")) return undefined

  try {
    const parsed: unknown = JSON.parse(stdout)
    const output = fieldValue(parsed, "hookSpecificOutput")
    return stringField(fieldValue(output, "updatedInput"), "command")
  } catch {
    // Fail open, like the guard itself. A parse bug must not break every
    // shell command.
    return undefined
  }
}

export default Plugin.define({
  id: "grunt",
  async setup(ctx) {
    if (process.env.HOME === undefined) return
    if (process.env.GRUNT_OFF === "1") return

    await ctx.tool.hook("execute.before", async (event) => {
      if (event.tool !== "read") return

      const path = stringField(event.input, "path") ?? stringField(event.input, "filePath")
      if (path === undefined) return

      const result = await guard("Read", {
        file_path: path,
        offset: numberField(event.input, "offset"),
        limit: numberField(event.input, "limit"),
      })

      // Exit 2 is the guard's deny. Throwing shows the reason to the model and
      // stops the read.
      if (result.code === 2) throw new Error(result.stderr.trim())
    })

    await ctx.shell.hook("create.before", async (event) => {
      const result = await guard("Bash", { command: event.command })

      // Exit 2 is the guard's deny for a bare whole-file read. OpenCode's shell
      // hook has no deny channel, so throw, as the read hook does.
      if (result.code === 2) throw new Error(result.stderr.trim())
      if (result.code !== 0) return

      // The cap wrapper is bash. Windows runs the tool's shell as PowerShell,
      // so leave the command alone there; the deny above still applies.
      if (BASH !== undefined) return

      const command = rewrittenCommand(result.stdout)
      if (command !== undefined) event.command = command
    })
  },
})
