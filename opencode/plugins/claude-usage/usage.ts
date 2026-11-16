import { spawn } from "node:child_process"
import { readFile } from "node:fs/promises"
import { homedir } from "node:os"
import { join } from "node:path"

/**
 * Claude subscription quota client.
 *
 * The `claude` binary reads its OAuth token from the OS credential store and
 * calls `GET /api/oauth/usage` with it, which is what `/status` shows. This
 * module reuses the same token and endpoint, so it needs no API key of its
 * own. Only the bearer header is required; no beta header or user agent.
 *
 * The token is never refreshed here: refreshing rotates Claude Code's refresh
 * token and can sign the CLI out. An expired token is reported instead.
 */

const USAGE_URL = "https://api.anthropic.com/api/oauth/usage"

/** Hard deadline for one usage request, covering both request and body read. */
const TIMEOUT_MS = 15_000

/** Deadline for the keychain lookup; `security` blocks on a UI prompt. */
const KEYCHAIN_TIMEOUT_MS = 10_000

const KEYCHAIN_SERVICE = "Claude Code-credentials"

/** One quota window, normalized from the API's snake_case body. */
export interface UsageWindow {
  percent?: number
  resetsAt?: string
}

/** The two windows Claude Code's `/status` reports. */
export interface ClaudeUsage {
  session?: UsageWindow
  weekly?: UsageWindow
}

interface Token {
  accessToken: string
  /** Epoch milliseconds, when the store records one. */
  expiresAt?: number
}

/**
 * Resolve Claude Code's OAuth token the way the CLI does: an explicit
 * `CLAUDE_CODE_OAUTH_TOKEN`, else the macOS keychain entry, else the
 * credentials file that Linux and Windows builds use.
 */
export async function resolveToken(): Promise<Token | undefined> {
  const fromEnv = process.env.CLAUDE_CODE_OAUTH_TOKEN?.trim()
  if (fromEnv) return { accessToken: fromEnv }

  if (process.platform === "darwin") {
    const fromKeychain = parseCredentials(await keychainSecret())
    if (fromKeychain) return fromKeychain
  }

  const raw = await readFile(credentialsPath(), "utf8").catch(() => undefined)
  return parseCredentials(raw)
}

/**
 * Fetch the usage windows for the signed-in subscription. The whole exchange,
 * including the body read, is bounded by `timeoutMs`.
 */
export async function fetchUsage(accessToken: string): Promise<ClaudeUsage> {
  const deadline = AbortSignal.timeout(TIMEOUT_MS)
  const timeoutMessage = `Claude usage request did not respond within ${TIMEOUT_MS}ms`

  let response: Response
  try {
    response = await withTimeout(
      fetch(USAGE_URL, {
        headers: { Authorization: `Bearer ${accessToken}`, Accept: "application/json" },
        // Never follow a redirect with the bearer attached.
        redirect: "error",
        signal: deadline,
      }),
      TIMEOUT_MS,
      timeoutMessage,
    )
  } catch {
    throw new Error(deadline.aborted ? timeoutMessage : `Could not reach ${USAGE_URL}`)
  }

  if (response.status === 401) {
    throw new Error("Claude OAuth token was rejected (HTTP 401). Run any claude command to refresh it.")
  }
  if (!response.ok) throw new Error(`Claude usage endpoint returned HTTP ${response.status}`)

  let body: unknown
  try {
    body = await withTimeout(response.json(), TIMEOUT_MS, timeoutMessage)
  } catch {
    throw new Error("Claude usage response was not valid JSON")
  }

  const usage = parseUsage(body)
  if (!usage) throw new Error("Claude usage response did not match the expected shape")
  return usage
}

/**
 * Normalize a `/api/oauth/usage` body. Tolerant by design: unknown fields (the
 * response carries a long list of internal experiment buckets) are ignored,
 * and a missing window stays absent instead of defaulting to 0%.
 */
export function parseUsage(body: unknown): ClaudeUsage | undefined {
  if (!isRecord(body)) return undefined

  const session = parseWindow(body.five_hour)
  const weekly = parseWindow(body.seven_day)
  if (!session && !weekly) return undefined

  return {
    ...(session ? { session } : {}),
    ...(weekly ? { weekly } : {}),
  }
}

function parseWindow(raw: unknown): UsageWindow | undefined {
  if (!isRecord(raw)) return undefined

  const percent = typeof raw.utilization === "number" ? clampPercent(raw.utilization) : undefined
  const resetsAt =
    typeof raw.resets_at === "string" && !Number.isNaN(Date.parse(raw.resets_at))
      ? raw.resets_at
      : undefined
  if (percent === undefined && resetsAt === undefined) return undefined

  return {
    ...(percent !== undefined ? { percent } : {}),
    ...(resetsAt !== undefined ? { resetsAt } : {}),
  }
}

function clampPercent(value: number): number {
  if (!Number.isFinite(value)) return 0
  return Math.max(0, Math.min(100, value))
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null
}

/** The JSON blob Claude Code writes: `{ claudeAiOauth: { accessToken, expiresAt } }`. */
function parseCredentials(raw: string | undefined): Token | undefined {
  if (!raw) return undefined

  let parsed: unknown
  try {
    parsed = JSON.parse(raw)
  } catch {
    return undefined
  }
  if (!isRecord(parsed)) return undefined

  const oauth = parsed.claudeAiOauth
  if (!isRecord(oauth)) return undefined

  const accessToken = typeof oauth.accessToken === "string" ? oauth.accessToken.trim() : ""
  if (!accessToken) return undefined

  const expiresAt = typeof oauth.expiresAt === "number" ? oauth.expiresAt : undefined
  return { accessToken, ...(expiresAt !== undefined ? { expiresAt } : {}) }
}

/** `security find-generic-password` prints the raw secret on stdout. */
function keychainSecret(): Promise<string | undefined> {
  return new Promise((resolve) => {
    const child = spawn("security", ["find-generic-password", "-s", KEYCHAIN_SERVICE, "-w"], {
      stdio: ["ignore", "pipe", "ignore"],
    })

    let stdout = ""
    child.stdout.setEncoding("utf8").on("data", (chunk: string) => {
      stdout += chunk
    })

    const timer = setTimeout(() => child.kill(), KEYCHAIN_TIMEOUT_MS)
    child.on("error", () => {
      clearTimeout(timer)
      resolve(undefined)
    })
    child.on("close", (code) => {
      clearTimeout(timer)
      resolve(code === 0 && stdout.trim() ? stdout.trim() : undefined)
    })
  })
}

function credentialsPath(): string {
  const dir = process.env.CLAUDE_CONFIG_DIR?.trim() || join(homedir(), ".claude")
  return join(dir, ".credentials.json")
}

/**
 * Settle `task` no later than `timeoutMs`. A plain timer is used because
 * signal dispatch does not reliably fire on a stalled fetch in every runtime
 * this plugin runs in.
 */
function withTimeout<T>(task: Promise<T>, timeoutMs: number, timeoutMessage: string): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(timeoutMessage)), timeoutMs)
    task.then(
      (value) => {
        clearTimeout(timer)
        resolve(value)
      },
      (error) => {
        clearTimeout(timer)
        reject(error)
      },
    )
  })
}
