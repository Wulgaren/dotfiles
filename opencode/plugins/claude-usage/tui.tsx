/** @jsxImportSource @opentui/solid */
import { For, type JSX } from "solid-js"
import { Plugin } from "@opencode/plugin/tui"
import type { Context } from "@opencode/plugin/tui/context"
import { formatCountdown, progressBar } from "./format.js"
import { fetchUsage, resolveToken, type ClaudeUsage, type UsageWindow } from "./usage.js"

const BAR_WIDTH = 12
const REFRESH_MS = 60_000

const ROWS = [
  { key: "session", label: "5h" },
  { key: "weekly", label: "wk" },
] as const

type Theme = Context["theme"]

type WidgetState =
  | { status: "loading" }
  | { status: "hidden" }
  | { status: "ok"; usage: ClaudeUsage }
  | { status: "error"; error: string; usage?: ClaudeUsage }

/**
 * Registers the refresh command. `keymap.layer` must be called from inside the
 * TUI component tree, so it lives on an `app`-slot claim that stays mounted for
 * the whole TUI lifetime.
 */
function CommandHost(props: { keymap: Pick<Context["keymap"], "layer">; refresh: () => void }): JSX.Element {
  props.keymap.layer(() => ({
    mode: "global",
    commands: [
      {
        id: "claude-usage.refresh",
        title: "Refresh Claude usage",
        group: "Claude",
        palette: true,
        run: () => props.refresh(),
      },
    ],
  }))
  return <box />
}

/**
 * Sidebar widget. Deliberately stateless: every value comes from one immutable
 * snapshot taken at mount time, because the packaged CLI repaints a plugin's
 * initial frame but not later signal updates (anomalyco/opencode#39986).
 * `setup` remounts the slot with a fresh snapshot when data changes, which is
 * a fresh initial paint.
 */
function UsageWidget(props: { state: WidgetState; theme: Theme }): JSX.Element {
  const theme = props.theme
  const state = props.state
  const usage = state.status === "ok" || state.status === "error" ? state.usage : undefined
  const dot =
    state.status === "loading"
      ? theme.text.muted
      : state.status === "error" && !usage
        ? theme.text.feedback.error.base
        : levelColor(theme, worstPercent(usage))

  const statusLine =
    state.status === "loading"
      ? "Loading…"
      : state.status === "error"
        ? (state.error ?? "Unavailable")
        : ""

  return (
    <box>
      <box flexDirection="row" gap={1}>
        <text fg={dot}>●</text>
        <text fg={theme.text.base}>
          <b>Claude usage</b>
        </text>
      </box>
      <For each={ROWS}>
        {(row) => <WindowRow label={row.label} window={usage?.[row.key]} theme={theme} />}
      </For>
      {statusLine !== "" ? (
        <text fg={theme.text.muted} wrapMode="none">
          {statusLine}
        </text>
      ) : null}
    </box>
  )
}

function WindowRow(props: { label: string; window: UsageWindow | undefined; theme: Theme }): JSX.Element {
  const theme = props.theme
  const raw = props.window?.percent
  const percent = typeof raw === "number" ? Math.round(raw) : undefined
  const color = levelColor(theme, percent)

  return (
    <box flexDirection="row" gap={1}>
      <text fg={theme.text.muted} width={3} wrapMode="none">
        {props.label}
      </text>
      <text fg={color} width={4} wrapMode="none">
        {percent === undefined ? "—" : `${percent}%`}
      </text>
      <text fg={color} wrapMode="none">
        {percent === undefined ? "" : progressBar(percent, BAR_WIDTH)}
      </text>
      <text fg={theme.text.muted} wrapMode="none">
        {formatCountdown(Date.now(), props.window?.resetsAt)}
      </text>
    </box>
  )
}

function worstPercent(usage: ClaudeUsage | undefined): number | undefined {
  if (!usage) return undefined
  const percents = [usage.session?.percent, usage.weekly?.percent].filter(
    (value): value is number => typeof value === "number",
  )
  return percents.length > 0 ? Math.max(...percents) : undefined
}

function levelColor(theme: Theme, percent: number | undefined): string {
  if (percent === undefined) return theme.text.muted
  if (percent >= 90) return theme.text.feedback.error.base
  if (percent >= 70) return theme.text.feedback.warning.base
  return theme.text.feedback.success.base
}

/**
 * Read the signed-in account's windows, or report that there is no Claude Code
 * login on this machine. The token never leaves the process: it is read from
 * the keychain here and used for one request.
 */
async function load(): Promise<ClaudeUsage | undefined> {
  const token = await resolveToken()
  if (!token) return undefined

  if (token.expiresAt !== undefined && token.expiresAt <= Date.now()) {
    throw new Error("Token expired. Run any claude command to refresh it.")
  }
  return fetchUsage(token.accessToken)
}

export default Plugin.define({
  id: "claude-usage",
  setup: (ctx) => {
    let last: WidgetState = { status: "loading" }
    let disposeWidget: (() => void) | null = null

    function paint(): void {
      disposeWidget?.()
      disposeWidget = null
      if (last.status === "hidden") return
      const snapshot = last
      disposeWidget = ctx.ui.slot({
        append: "sidebar.content",
        render: () => <UsageWidget state={snapshot} theme={ctx.theme} />,
      })
    }

    // Guards against out-of-order results: a slow fetch finishing after a newer
    // one, or after cleanup, is discarded.
    let generation = 0
    let announced: string | null = null

    async function refresh(): Promise<void> {
      const current = ++generation
      let next: WidgetState

      try {
        const usage = await load()
        if (current !== generation) return
        announced = null
        if (!usage) {
          last = { status: "hidden" }
          paint()
          return
        }
        next = { status: "ok", usage }
      } catch (error) {
        if (current !== generation) return
        const message = error instanceof Error ? error.message : String(error)
        if (announced !== message) {
          announced = message
          ctx.ui.toast.show({ variant: "error", title: "Claude usage", message, duration: 6000 })
        }
        next = { status: "error", error: message, usage: last.usage }
      }

      if (current !== generation) return
      last = next
      paint()
    }

    const disposeCommands = ctx.ui.slot({
      append: "app",
      render: () => <CommandHost keymap={ctx.keymap} refresh={() => void refresh()} />,
    })

    paint()
    void refresh()
    const timer = setInterval(() => void refresh(), REFRESH_MS)

    return () => {
      generation++
      clearInterval(timer)
      disposeWidget?.()
      disposeCommands()
    }
  },
})
