import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { formatCountdown, progressBar } from "./format.ts"
import { parseUsage } from "./usage.ts"

/** Trimmed copy of a real `/api/oauth/usage` body. */
const RESPONSE = {
  five_hour: {
    utilization: 18.0,
    resets_at: "2026-11-16T17:09:59.745798+00:00",
    limit_dollars: null,
    used_dollars: null,
    locked_reason: null,
  },
  seven_day: {
    utilization: 86.0,
    resets_at: "2026-11-20T23:59:59.745824+00:00",
    limit_dollars: null,
  },
  seven_day_opus: null,
  seven_day_sonnet: null,
  extra_usage: { is_enabled: false, monthly_limit: null },
  limits: [{ kind: "weekly_all", group: "weekly", percent: 86, severity: "warning" }],
}

describe("parseUsage", () => {
  it("maps the two windows Claude Code reports", () => {
    assert.deepEqual(parseUsage(RESPONSE), {
      session: { percent: 18, resetsAt: "2026-11-16T17:09:59.745798+00:00" },
      weekly: { percent: 86, resetsAt: "2026-11-20T23:59:59.745824+00:00" },
    })
  })

  it("keeps an absent window absent instead of defaulting to 0%", () => {
    assert.deepEqual(parseUsage({ seven_day: RESPONSE.seven_day }), {
      weekly: { percent: 86, resetsAt: "2026-11-20T23:59:59.745824+00:00" },
    })
  })

  it("clamps utilization into 0..100", () => {
    assert.equal(parseUsage({ five_hour: { utilization: 140 } })?.session?.percent, 100)
    assert.equal(parseUsage({ five_hour: { utilization: -3 } })?.session?.percent, 0)
  })

  it("drops an unparseable reset timestamp", () => {
    assert.deepEqual(parseUsage({ five_hour: { utilization: 5, resets_at: "soon" } }), {
      session: { percent: 5 },
    })
  })

  it("rejects bodies with no usable window", () => {
    assert.equal(parseUsage({}), undefined)
    assert.equal(parseUsage({ five_hour: null, seven_day: null }), undefined)
    assert.equal(parseUsage("nope"), undefined)
  })
})

describe("formatCountdown", () => {
  const now = Date.parse("2026-11-16T12:00:00Z")

  it("renders minutes, hours, and days", () => {
    assert.equal(formatCountdown(now, "2026-11-16T12:42:00Z"), "42m")
    assert.equal(formatCountdown(now, "2026-11-16T15:12:00Z"), "3h 12m")
    assert.equal(formatCountdown(now, "2026-11-19T16:00:00Z"), "3d 4h")
  })

  it("reports a passed reset and an empty input", () => {
    assert.equal(formatCountdown(now, "2026-11-16T11:00:00Z"), "resets now")
    assert.equal(formatCountdown(now, undefined), "")
  })
})

describe("progressBar", () => {
  it("fills in proportion and clamps out-of-range values", () => {
    assert.equal(progressBar(0, 4), "░░░░")
    assert.equal(progressBar(50, 4), "██░░")
    assert.equal(progressBar(100, 4), "████")
    assert.equal(progressBar(180, 4), "████")
  })
})
