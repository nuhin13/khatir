---
id: T-009
epic: EPIC-03
title: Landlord home shell body
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [EPIC-02.T-004, T-007]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-009 · Landlord home shell body

## 1. Feature goal
Fill the landlord shell's Home tab with the `home` design: greeting, the prominent "Create DMP form" CTA, a collection summary card, and quick stats — the daily landing screen.

## 2. Business logic
Per `home` design. The DMP CTA routes to add-tenant (EPIC-04). The collection/chart card shows real portfolio summary (T-005) for counts; the detailed charts come in EPIC-09 (placeholder card region marked). Late-payers list is EPIC-07/09 (placeholder now).

## 3. What this task DOES
- `features/properties/presentation/screens/landlord_home_screen.dart` matching `home`.
- Greeting (name), DMP CTA card, collection summary card (from portfolio summary), quick stat tiles.
- Mark chart/late-payer regions with `// TODO(EPIC-09)` placeholders.
- Wire into landlord shell Home branch. Loading/error/empty/data. Widget test.

## 4. What this task does NOT do
- Charts (EPIC-09), rent actions (EPIC-07), add-tenant flow (EPIC-04) — CTA routes to placeholder until EPIC-04.

## 5. Files & changes
### Add
- `features/properties/presentation/screens/landlord_home_screen.dart`
- ARB keys; `test/landlord_home_test.dart`
### Update
- `features/shell/landlord_shell.dart` — Home branch renders this

## 6. Database changes
None.
## 7. API changes
Consumes /portfolio (T-005).

## 8. UI changes
- **Design source:** screen `home` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-landlord.js` → `reg('home')`)
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/landlord/home`
- Translate greeting + DMP CTA + collection card + stat tiles; values from packages/design-tokens
- States: loading/error/empty (no buildings yet → friendly empty)/data
- Navigation: DMP CTA → `/tenants/add` (placeholder until EPIC-04); Add building → `/properties/add`
- i18n keys: `home_greeting`, `home_dmp_cta`, `home_collected`, `home_stats_*`, `home_empty` (bn + en) — lift copy from `home`

## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] landlord_home_screen matches `home` design
- [ ] DMP CTA card → add-tenant route
- [ ] collection summary from /portfolio
- [ ] quick stat tiles
- [ ] chart/late-payer placeholders marked TODO(EPIC-09)
- [ ] empty state (no buildings)
- [ ] wired into landlord shell Home branch
- [ ] ARB bn + en; Widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- landlord_home_test → renders CTA + summary; empty state when no buildings
### Manual QA
1. Fresh landlord (no buildings) → empty state + add-building CTA. With buildings → summary populates.

## 13. Acceptance criteria
- [ ] Home matches design; summary live; CTA routes; all states present.
- [ ] **Screen `home` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens via theme; later-epic regions marked
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- The big sage "DMP ফর্ম তৈরি করুন · Police form · 2 minutes" CTA is the hero — match its prominence. Chart card area is EPIC-09; show a simple summary now.
