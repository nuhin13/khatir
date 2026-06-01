// GENERATED FILE — do not edit by hand.
// Source: packages/design-tokens/tokens.json
// Regenerate: node packages/design-tokens/generate.mjs

export const colors = {
  "ink": "#2C3530",
  "ink2": "#3D4A42",
  "sage": "#7BA084",
  "sageDk": "#5C8067",
  "sageBg": "#E8F0EA",
  "rose": "#E89B8B",
  "roseDk": "#C9755F",
  "roseBg": "#FBE9E3",
  "butter": "#F4D58D",
  "butterDk": "#D9B45F",
  "butterBg": "#FBF1D8",
  "danger": "#D14D3B",
  "dangerBg": "#FBE5E1",
  "cream": "#FBF6EE",
  "card": "#FFFFFF",
  "line": "#EFE6D8",
  "lineDk": "#E0D5C2",
  "muted": "#8C8578",
  "mutedDk": "#6B6558"
} as const;

export const radius = {
  "xs": 10,
  "sm": 14,
  "tile": 16,
  "md": 18,
  "lg": 22,
  "card": 22,
  "xl": 26,
  "pill": 999,
  "button": 999,
  "chip": 999
} as const;

export const spacing = {
  "s1": 4,
  "s2": 8,
  "s3": 12,
  "s4": 16,
  "s5": 20,
  "s6": 24,
  "s7": 32,
  "s8": 40
} as const;

export const fonts = {
  "title": "Plus Jakarta Sans",
  "body": "Hind Siliguri",
  "hand": "Caveat",
  "mono": "JetBrains Mono",
  "titleStack": "'Plus Jakarta Sans', 'Hind Siliguri', -apple-system, sans-serif",
  "bodyStack": "'Hind Siliguri', 'Noto Sans Bengali', -apple-system, sans-serif",
  "handStack": "'Caveat', 'Hind Siliguri', cursive",
  "monoStack": "'JetBrains Mono', 'Menlo', monospace"
} as const;

export const tokens = { colors, radius, spacing, fonts } as const;
export default tokens;
