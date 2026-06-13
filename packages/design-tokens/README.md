# @khatir/design-tokens

Single source of truth for the **Notun Din** design tokens — colors, radii, spacing,
and font families — consumable by **both** the Flutter app and the Next.js admin so the
palette never drifts between surfaces.

## Layout

```
packages/design-tokens/
  tokens.json              ← the ONE source of truth (edit here)
  generate.mjs             ← regenerates the bindings below from tokens.json
  dart/khatir_tokens.dart  ← GENERATED — Flutter consumes (T-008)
  ts/tokens.ts             ← GENERATED — admin TS consumes (T-009)
  ts/tailwind-preset.js    ← GENERATED — admin Tailwind config consumes (T-009)
```

`dart/`, `ts/tokens.ts`, and `ts/tailwind-preset.js` are **generated**. Never edit them
by hand — they carry a "do not edit" banner and will be overwritten.

## How to add or change a token

1. Edit `tokens.json` (the only file you touch by hand). It has four groups:
   `color`, `radius`, `spacing`, `font`.
2. Regenerate the bindings:

   ```sh
   node generate.mjs        # or: npm run generate
   ```

3. Commit `tokens.json` **and** the regenerated `dart/` + `ts/` outputs together.

That single edit + regenerate updates both Flutter and the admin app.

## Consuming the tokens

### Flutter (T-008)

```dart
import 'package:design_tokens/dart/khatir_tokens.dart';

Container(
  color: KhatirColors.sage,
  child: ..., // KhatirRadius.card, KhatirSpacing.s4, KhatirFonts.title
);
```

### Next.js admin (T-009)

TypeScript values:

```ts
import { colors, radius, spacing, fonts } from '@khatir/design-tokens';
colors.sage; // "#7BA084"
```

Tailwind preset (in `tailwind.config.js`):

```js
module.exports = {
  presets: [require('@khatir/design-tokens/tailwind-preset')],
};
// → bg-sage, rounded-card, p-s4, font-title, etc.
```

## Token reference (Notun Din)

| Group   | Keys |
| ------- | ---- |
| color   | ink, ink2, sage, sageDk, sageBg, rose, roseDk, roseBg, butter, butterDk, butterBg, danger, dangerBg, cream, card, line, lineDk, muted, mutedDk |
| radius  | xs 10, sm 14, tile 16, md 18, lg 22, card 22, xl 26, pill 999, button 999, chip 999 |
| spacing | s1 4 … s8 40 (4pt scale) |
| font    | title "Plus Jakarta Sans", body "Hind Siliguri", hand "Caveat", mono "JetBrains Mono" |

Values are taken verbatim from the prototype `:root` in
`documnets/docs/design/khatir-ui/styles/khatir.css`.
