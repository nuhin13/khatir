# Khatir UI — Design Prototype (in-repo export)

This is the **exported copy** of the Khatir mobile/role design prototype, so any CLI/agent (Claude Code, Codex, OpenCode, etc.) can read the design without needing access to Claude Design.

**Live version (your account):**
`https://claude.ai/design/p/95a5aed6-a19d-4484-a3f0-8267f8c68ac8?file=khatir%2FKhatir+Mobile+Prototype.html`

## What's here

- `Khatir Mobile Prototype.html` — open in a browser to see the interactive prototype.
- `proto/*.js` — the actual screen definitions (the source of truth for layout/copy):
  - `screens-onboard.js` — splash, intro, login, otp, roleChooser
  - `screens-landlord.js` — home, addBuilding, portfolio, unit
  - `screens-landlord2.js` — addTenant, ocr, voice, manualTenant, dmp, dmpPdf, rentReq, verifyPay, receipt, expenses, addExpense, dashboard, more, verify, lease, warning, plan
  - `screens-other.js` — manager / tenant / web-link / caretaker screens
  - `home-variants.js` — exploration only (ignore for production; canonical home is `reg('home')`)
  - `proto.css` — prototype CSS tokens (match `packages/design-tokens`)
  - `ui.js` — shared helpers → become Flutter `lib/core/widgets/`
- `styles/`, `assets/` — supporting CSS/icons/images.

## How to use it

Each screen is registered as `reg('<screenKey>', { en, bn, render(){…} })`. To find a screen, search the `proto/*.js` files for `reg('<screenKey>'`.

**The mapping of every screen → epic → task is in `docs/architecture/07_design_map.md`.** Start there. A UI task names its `<screenKey>`; you open it here (or in Claude Design) and translate it to Flutter.

## The one rule

The prototype is the **layout/composition/copy truth**. The **values** (colors, spacing, radii, fonts) come from `packages/design-tokens` — do not hardcode the prototype's inline hex/px. They already match, so output is identical but stays maintainable from one source.
