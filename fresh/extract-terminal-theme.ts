#!/usr/bin/env bun
/**
 * Extracts colors from an Apple Terminal .terminal (plist) file and writes
 * terminal-palette.json so theme-from-terminal.ts can use them.
 *
 * Usage: bun run fresh/extract-terminal-theme.ts [path-to.terminal]
 *        If no path given, uses the first .terminal file in fresh/
 */

const DIR = import.meta.dir;
const PALETTE_PATH = `${DIR}/terminal-palette.json`;

const KEY_TO_PALETTE: Record<string, string> = {
  BackgroundColor: "background",
  TextColor: "foreground",
  ANSIBlackColor: "black",
  ANSIRedColor: "red",
  ANSIGreenColor: "green",
  ANSIYellowColor: "yellow",
  ANSIBlueColor: "blue",
  ANSIMagentaColor: "magenta",
  ANSICyanColor: "cyan",
  ANSIWhiteColor: "white",
  ANSIBrightBlackColor: "brightBlack",
  ANSIBrightRedColor: "brightRed",
  ANSIBrightGreenColor: "brightGreen",
  ANSIBrightYellowColor: "brightYellow",
  ANSIBrightBlueColor: "brightBlue",
  ANSIBrightMagentaColor: "brightMagenta",
  ANSIBrightCyanColor: "brightCyan",
  ANSIBrightWhiteColor: "brightWhite",
};

function rgbFromNsColorData(base64: string, preferZeroOne = false): string | null {
  const raw = Buffer.from(base64, "base64").toString("binary");
  const re = /(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)/g;
  let match: RegExpExecArray | null;
  let best: RegExpExecArray | null = null;
  while ((match = re.exec(raw)) !== null) {
    const a = parseFloat(match[1]);
    const b = parseFloat(match[2]);
    const c = parseFloat(match[3]);
    const allZeroOne = a <= 1 && b <= 1 && c <= 1;
    if (preferZeroOne) {
      if (allZeroOne) {
        best = match;
        break;
      }
    } else {
      best = match;
      break;
    }
  }
  if (!best) return null;
  const toByte = (s: string) => {
    const n = parseFloat(s);
    return Math.min(255, Math.round(n > 1 ? n : n * 255));
  };
  const r = toByte(best[1]);
  const g = toByte(best[2]);
  const b = toByte(best[3]);
  return `#${r.toString(16).padStart(2, "0")}${g.toString(16).padStart(2, "0")}${b.toString(16).padStart(2, "0")}`;
}

function extractColorsFromPlist(xml: string): Record<string, string> {
  const palette: Record<string, string> = {};
  const keyRegex = /<key>([^<]+)<\/key>\s*<data>\s*([\s\S]*?)\s*<\/data>/g;
  let m: RegExpExecArray | null;
  while ((m = keyRegex.exec(xml)) !== null) {
    const key = m[1];
    const data = m[2].replace(/\s/g, "");
    const paletteKey = KEY_TO_PALETTE[key];
    if (paletteKey) {
      const preferZeroOne = key === "BackgroundColor";
      const hex = rgbFromNsColorData(data, preferZeroOne);
      if (hex) palette[paletteKey] = hex;
    }
  }
  return palette;
}

function ensureFullPalette(palette: Record<string, string>): Record<string, string> {
  const defaults: Record<string, string> = {
    background: "#303446",
    foreground: "#c6d0f5",
    black: "#51576d",
    red: "#e78284",
    green: "#a6d189",
    yellow: "#e5c890",
    blue: "#8caaee",
    magenta: "#f4b8e4",
    cyan: "#81c8be",
    white: "#b5bfe2",
    brightBlack: "#626880",
    brightRed: "#e78284",
    brightGreen: "#a6d189",
    brightYellow: "#e5c890",
    brightBlue: "#8caaee",
    brightMagenta: "#f4b8e4",
    brightCyan: "#81c8be",
    brightWhite: "#c6d0f5",
  };
  return { ...defaults, ...palette };
}

async function main() {
  const arg = process.argv[2];
  let path: string;
  if (arg) {
    path = arg.startsWith("/") ? arg : `${process.cwd()}/${arg}`;
  } else {
    const entries = await Array.fromAsync(
      new Bun.Glob("*.terminal").scan({ cwd: DIR, absolute: true })
    );
    if (entries.length === 0) {
      console.error("No .terminal file found in fresh/. Pass a path: bun run fresh/extract-terminal-theme.ts path/to/file.terminal");
      process.exit(1);
    }
    path = entries[0];
  }

  const xml = await Bun.file(path).text();
  const palette = extractColorsFromPlist(xml);
  const full = ensureFullPalette(palette);
  await Bun.write(PALETTE_PATH, JSON.stringify(full, null, 2));
  console.log(`Extracted ${Object.keys(palette).length} colors from ${path}`);
  console.log(`Wrote ${PALETTE_PATH}`);
  console.log("Run: bun run fresh/theme-from-terminal.ts");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
