#!/usr/bin/env bun
/**
 * Generates a Fresh editor theme from terminal palette colors.
 * Edit terminal-palette.json with your terminal's hex colors, then run:
 *   bun run fresh/theme-from-terminal.ts
 * Theme is written to fresh/themes/terminal.json (or ~/.config/fresh/themes/ when linked).
 */

const DIR = import.meta.dir;
const PALETTE_PATH = `${DIR}/terminal-palette.json`;
const THEMES_DIR = `${DIR}/themes`;
const THEME_NAME = "terminal";

function hexToRgb(hex: string): [number, number, number] {
  const m = hex.replace(/^#/, "").match(/^(..)(..)(..)$/);
  if (!m) throw new Error(`Invalid hex: ${hex}`);
  return [parseInt(m[1], 16), parseInt(m[2], 16), parseInt(m[3], 16)];
}

type Palette = Record<string, string>;

function buildTheme(p: Palette) {
  const r = (key: keyof Palette) => hexToRgb(p[key] ?? "#000000");

  return {
    name: THEME_NAME,
    editor: {
      bg: "Default",
      line_number_bg: "Default",
      current_line_bg: "Default",
      fg: r("foreground"),
      cursor: r("blue"),
      selection_bg: r("brightBlack"),
    },
    syntax: {
      keyword: r("magenta"),
      string: r("green"),
      comment: r("brightBlack"),
    },
    diagnostic: {
      error_fg: r("red"),
      error_bg: r("red"),
      warning_fg: r("yellow"),
      warning_bg: r("yellow"),
      hint_fg: r("cyan"),
      hint_bg: r("cyan"),
      info_fg: r("blue"),
      info_bg: r("blue"),
    },
    search: {
      match_bg: r("yellow"),
      match_fg: r("black"),
    },
    ui: {
      tab_active_bg: r("background"),
      tab_active_fg: r("foreground"),
      tab_inactive_bg: r("black"),
      tab_inactive_fg: r("brightBlack"),
      status_bar_bg: r("black"),
      status_bar_fg: r("brightBlack"),
    },
  };
}

async function main() {
  const raw = await Bun.file(PALETTE_PATH).text();
  const palette: Palette = JSON.parse(raw);
  const theme = buildTheme(palette);

  const fs = await import("fs");
  fs.mkdirSync(THEMES_DIR, { recursive: true });
  const outPath = `${THEMES_DIR}/${THEME_NAME}.json`;
  await Bun.write(outPath, JSON.stringify(theme, null, 2));
  console.log(`Wrote theme to ${outPath}`);
  console.log("In Fresh: Ctrl+P → \"Select Theme\" → \"terminal\"");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
