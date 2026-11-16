/**
 * Terse formatting helpers for the sidebar widget. Output targets a narrow
 * sidebar, so strings stay short.
 */

/** Renders the time until a reset as "42m", "3h 12m", "2d 4h", or "resets now". */
export function formatCountdown(now: number, resetsAt: string | undefined): string {
  if (!resetsAt) return ""
  const target = Date.parse(resetsAt)
  if (!Number.isFinite(target)) return ""

  const remainingMs = target - now
  if (remainingMs <= 0) return "resets now"

  const minutes = Math.max(1, Math.round(remainingMs / 60_000))
  if (minutes < 60) return `${minutes}m`

  const hours = Math.floor(minutes / 60)
  if (hours < 24) {
    const rest = minutes % 60
    return rest === 0 ? `${hours}h` : `${hours}h ${rest}m`
  }

  const days = Math.floor(hours / 24)
  const rest = hours % 24
  return rest === 0 ? `${days}d` : `${days}d ${rest}h`
}

/** A unicode progress bar; percent is clamped to 0..100. */
export function progressBar(percent: number, width: number): string {
  const clamped = Number.isFinite(percent) ? Math.max(0, Math.min(100, percent)) : 0
  const filled = Math.round((clamped / 100) * width)
  return "█".repeat(filled) + "░".repeat(width - filled)
}
