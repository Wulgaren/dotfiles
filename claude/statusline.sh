#!/bin/bash
# Wrapper to invoke TypeScript statusline script using bun
exec bun run "$(dirname "$0")/statusline.ts"
