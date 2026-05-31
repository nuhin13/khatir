# Khatir — Execution Plan: COMPLETE

All 26 epics (EPIC-00 → EPIC-26) are fully specced. Every task has frontmatter,
design anchor (where UI), implementation checklist with the git-hash logging
convention, test plan, acceptance criteria, and self-review.

## Totals
- **27 epic folders** (EPIC-00 foundation + EPIC-01–26)
- **302 task files** (`T-XXX.md`)
- **44 / 44 prototype screens** assigned to concrete tasks (0 `_TBD_`)

## Phases
- **MVP (EPIC-00–16):** 196 tasks — the shippable product (onboarding → properties →
  tenants/NID OCR → DMP form → leases → rent collection → expenses → dashboard →
  pricing → full admin portal).
- **P1 (EPIC-17–23):** NID verification, AI lease, tenant app, private warnings,
  mutual reviews, B2B manager, chatbot.
- **P2 (EPIC-24–25):** tenancy history flags (consent-per-share), gatekeeper/caretaker.
- **P3 (EPIC-26):** government export.

## How to build
1. Extract this bundle into your repo, commit, push to GitHub.
2. Open the repo in Claude Code (CLI or claude.ai/code).
3. First prompt: read `docs/architecture/00_overview.md` → `01`–`07` + `enums.md`,
   then `docs/epics/_handoff_protocol.md` + `_task_template.md`.
4. Execute `EPIC-00/T-001` first (no dependencies), then `make next`.

## Build order
Follow `docs/epics/_master_plan.md` dependencies. Lanes (`make next LAYER=backend|mobile|admin|infra`)
let multiple agents work in parallel. The MVP (EPIC-00–16) is independently shippable
before any P1+ work.

## Legal-safety invariants (enforced in specs + tests)
- No public/searchable reputation database (EPIC-21 T-009, EPIC-24 T-010 prove it).
- Reputation features (warnings/reviews/history) are private, consent-gated, kill-switchable.
- NID: encrypted + masked; verification returns Matched/Not Matched only; never "Porichoy".
- The DMP form is the wedge; EPIC-05 T-010 is a hard release gate (verify against the real form).
