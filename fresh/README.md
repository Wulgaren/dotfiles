# Fresh editor config

## Theme from terminal colors

To make Fresh use the same colors as your terminal:

1. **Get a palette** (either):
   - **From an Apple Terminal theme (`.terminal`):** put the `.terminal` file in this folder and run:
     ```bash
     bun run fresh/extract-terminal-theme.ts
     ```
     Or pass a path: `bun run fresh/extract-terminal-theme.ts path/to/file.terminal`
   - **By hand:** edit `terminal-palette.json` with hex values for `background`, `foreground`, and the 16 ANSI colors (`black`, `red`, … `brightWhite`). Copy from your terminal config (WezTerm, Alacritty, Kitty, iTerm).

2. **Generate the Fresh theme**
   ```bash
   bun run fresh/theme-from-terminal.ts
   ```
   This writes `themes/terminal.json`.

3. **Use the theme in Fresh**  
   `Ctrl+P` → “Select Theme” → “terminal”.

If `~/.config/fresh` is symlinked to this `fresh/` folder, the theme is picked up automatically. After changing `terminal-palette.json`, run the script again and reselect the theme in Fresh.
