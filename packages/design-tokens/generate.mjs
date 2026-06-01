#!/usr/bin/env node
// Khatir design-tokens generator.
// Reads tokens.json (the single source of truth) and regenerates the
// Dart bindings (Flutter) and TS bindings + Tailwind preset (Next.js admin).
//
// Usage: node generate.mjs

import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = __dirname;

const tokens = JSON.parse(readFileSync(join(root, "tokens.json"), "utf8"));
const { color, radius, spacing, font } = tokens;

const BANNER_LINES = [
  "GENERATED FILE — do not edit by hand.",
  "Source: packages/design-tokens/tokens.json",
  "Regenerate: node packages/design-tokens/generate.mjs",
];

function ensureDir(p) {
  mkdirSync(dirname(p), { recursive: true });
}

// ── camelCase -> snake_case (for Dart kebab-free constant names we keep camelCase) ──
function dartHex(hex) {
  // #RRGGBB -> 0xFFRRGGBB
  return "0xFF" + hex.replace("#", "").toUpperCase();
}

// ─────────────────────────── Dart ───────────────────────────
function generateDart() {
  const out = [];
  out.push(BANNER_LINES.map((l) => "// " + l).join("\n"));
  out.push("");
  out.push("import 'dart:ui';");
  out.push("");
  out.push("/// Notun Din palette + scale, generated from tokens.json.");
  out.push("class KhatirColors {");
  out.push("  KhatirColors._();");
  for (const [k, v] of Object.entries(color)) {
    out.push(`  static const Color ${k} = Color(${dartHex(v)});`);
  }
  out.push("}");
  out.push("");
  out.push("class KhatirRadius {");
  out.push("  KhatirRadius._();");
  for (const [k, v] of Object.entries(radius)) {
    out.push(`  static const double ${k} = ${Number(v).toFixed(1)};`);
  }
  out.push("}");
  out.push("");
  out.push("class KhatirSpacing {");
  out.push("  KhatirSpacing._();");
  for (const [k, v] of Object.entries(spacing)) {
    out.push(`  static const double ${k} = ${Number(v).toFixed(1)};`);
  }
  out.push("}");
  out.push("");
  out.push("class KhatirFonts {");
  out.push("  KhatirFonts._();");
  out.push(`  static const String title = '${font.title}';`);
  out.push(`  static const String body = '${font.body}';`);
  out.push(`  static const String hand = '${font.hand}';`);
  out.push(`  static const String mono = '${font.mono}';`);
  out.push("}");
  out.push("");
  return out.join("\n");
}

// ─────────────────────────── TS ───────────────────────────
function generateTs() {
  const out = [];
  out.push(BANNER_LINES.map((l) => "// " + l).join("\n"));
  out.push("");
  out.push(`export const colors = ${JSON.stringify(color, null, 2)} as const;`);
  out.push("");
  out.push(`export const radius = ${JSON.stringify(radius, null, 2)} as const;`);
  out.push("");
  out.push(`export const spacing = ${JSON.stringify(spacing, null, 2)} as const;`);
  out.push("");
  out.push(`export const fonts = ${JSON.stringify(font, null, 2)} as const;`);
  out.push("");
  out.push("export const tokens = { colors, radius, spacing, fonts } as const;");
  out.push("export default tokens;");
  out.push("");
  return out.join("\n");
}

// ─────────────────────── Tailwind preset ───────────────────────
function generateTailwindPreset() {
  // borderRadius + spacing want px strings; colors want hex.
  const radiusPx = {};
  for (const [k, v] of Object.entries(radius)) {
    radiusPx[k] = v >= 999 ? "9999px" : `${v}px`;
  }
  const spacingPx = {};
  for (const [k, v] of Object.entries(spacing)) {
    spacingPx[k] = `${v}px`;
  }
  const fontFamily = {
    title: [font.title, "Hind Siliguri", "sans-serif"],
    body: [font.body, "Noto Sans Bengali", "sans-serif"],
    hand: [font.hand, "Hind Siliguri", "cursive"],
    mono: [font.mono, "Menlo", "monospace"],
  };
  const out = [];
  out.push(BANNER_LINES.map((l) => "// " + l).join("\n"));
  out.push("");
  out.push("/** @type {import('tailwindcss').Config} */");
  out.push("module.exports = {");
  out.push("  theme: {");
  out.push("    extend: {");
  out.push(`      colors: ${JSON.stringify(color, null, 8).replace(/\n/g, "\n      ")},`);
  out.push(`      borderRadius: ${JSON.stringify(radiusPx, null, 8).replace(/\n/g, "\n      ")},`);
  out.push(`      spacing: ${JSON.stringify(spacingPx, null, 8).replace(/\n/g, "\n      ")},`);
  out.push(`      fontFamily: ${JSON.stringify(fontFamily, null, 8).replace(/\n/g, "\n      ")},`);
  out.push("    },");
  out.push("  },");
  out.push("};");
  out.push("");
  return out.join("\n");
}

const targets = [
  [join(root, "dart", "khatir_tokens.dart"), generateDart()],
  [join(root, "ts", "tokens.ts"), generateTs()],
  [join(root, "ts", "tailwind-preset.js"), generateTailwindPreset()],
];

for (const [path, content] of targets) {
  ensureDir(path);
  writeFileSync(path, content, "utf8");
  console.log("wrote", path.replace(root + "/", ""));
}

console.log("done — tokens regenerated from tokens.json");
