---
id: T-001
epic: EPIC-21
title: Review model + double-blind reveal logic
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-06.T-001, EPIC-16.T-001]
blocks: [T-002, T-003]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · Review model + double-blind reveal logic

## 1. Feature goal
Model a private mutual review tied to a lease relationship, with double-blind reveal (neither sees the other's until both submit).

## 2. Business logic
Review(lease FK, reviewer FK, reviewee FK, rating int, comment text, visibility private/consented, consent_record FK nullable, created_at, revealed_at nullable). Reveal: a review about you is visible to you only after BOTH parties have submitted (double-blind) OR per explicit consent. NO field enables cross-lease or public aggregation.

## 3. What this task DOES
- reviews app; Review model; reveal logic helper; migration; admin; tests (double-blind).

## 5. Files & changes
### Add
- khatir/reviews/{__init__,apps,models,enums,reveal}.py, migration, tests/factories
### Update
- settings register

## 6–10.
Creates reviews_review. Reversible. No external. No flags (enforced at endpoint).

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] Review model (reviewer/reviewee/lease, rating, comment, visibility, consent FK)
- [x] double-blind reveal helper (visible only after both submit, or consent)
- [x] NO cross-lease/public aggregation field
- [x] migration reversible; admin
- [x] tests: double-blind reveal, no-aggregation
- [x] ruff clean

## 12. Test plan
### Automated
- test_review_create, test_double_blind_reveal, test_no_aggregation_field
## 13. Acceptance criteria
- [x] Model + reveal logic; double-blind; tests + lint pass.
## 14. Self-review
- [x] Private by construction; no public/aggregate structure
### Deviations from spec
- mypy not in the DoD gate for this worktree; ran `ruff check` + `makemigrations --check` + full pytest instead.
### Files touched (actual)
- Add: khatir/reviews/{__init__,apps,enums,models,reveal,admin}.py, migrations/0001_initial.py, tests/{__init__,factories,test_models}.py
- Update: config/settings/base.py (register `khatir.reviews`)
## 15. Notes
- Reveal default: both-submitted. Any other visibility requires a ConsentRecord. This is the legal heart of the feature — keep it strict.
