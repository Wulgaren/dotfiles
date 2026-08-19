# Netlify: Prefer Edge Functions

Must always apply when working with Netlify deployment, serverless functions, or edge functions. Triggers on Netlify config, `netlify.toml`, or choosing between edge vs serverless.

---

When working with Netlify, prefer **Edge Functions** over Netlify serverless (Node) functions when both can satisfy the requirement.

## Why

- Run at the edge (lower latency, globally distributed)
- No cold starts
- Same config surface (`netlify.toml`) and deployment flow

## Where

- **Edge**: `netlify/edge-functions/<name>.ts` (or `.js`)
- **Serverless**: `netlify/functions/` — use only when you need Node APIs, longer timeouts, or binary/body size limits that edge doesn't support

## Examples

**Redirects / rewrites / light logic** → Edge function.

```toml
# netlify.toml
[[edge_functions]]
  function = "auth-or-redirect"
  path = "/app/*"
```

**Heavy Node deps, big payloads, or long runs** → Serverless function.

Default to edge; choose serverless only when necessary.
