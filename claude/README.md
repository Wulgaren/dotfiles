# Claude Code statusline

Shows the working directory, git branch, model, and claude.ai rate-limit usage.

```
~/Coding/project (main) | Opus | 5h 12% (resets 15:30) | 7d 40% (resets Mon 09:00)
```

`statusline.sh` reads the JSON Claude Code sends on stdin. The branch is looked
up with `git` (it is not in the JSON), and the rate-limit segments are omitted
when the fields are absent (non-subscription, or before the first API response).

## Setup

`~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

Requires `jq` and `git` on `PATH`.
