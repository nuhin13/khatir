---
id: T-014
epic: EPIC-03
title: Unit generation parity (UI↔API)
layer: cross-cutting
size: S
status: todo
preferred_agent: codex
depends_on: [T-004, T-011]
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

# T-014 · Unit generation parity (UI↔API)

## 1. Feature goal
Guarantee the Flutter wizard's unit-label generation produces identical labels to the backend generator for the same inputs, so what the user previews is exactly what gets saved.

## 2. Business logic
Both sides implement the same rules (letter `1A`, number `101`, customs, removals). This task locks them together with shared test vectors so they can never silently diverge.

## 3. What this task DOES
- Define a small set of canonical input→output vectors (e.g. 3×2 letter, 2×3 number, with a custom + a removal).
- Add a backend test asserting the API generator matches the vectors.
- Add a Flutter test asserting the client generator matches the same vectors.
- Document the shared rule in `properties` (backend) and `unit_label_gen.dart` (client) referencing each other.

## 5. Files & changes
### Add
- `apps/api/.../tests/test_generation_parity.py`
- `apps/mobile/test/unit_gen_parity_test.dart`
- a shared `docs/design/khatir-ui/` note or a `UNIT_GENERATION.md` capturing the vectors
### Update
- comments cross-referencing both implementations

## 6. Database changes
None.
## 7. API changes
None.
## 8. UI changes
No UI changes.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] Canonical vectors documented
- [ ] Backend test matches vectors
- [ ] Flutter test matches vectors
- [ ] Cross-reference comments in both implementations
- [ ] both test suites pass

## 12. Test plan
### Automated
- parity vectors pass on both backend + client
### Manual QA
1. Generate same config on both → identical labels.

## 13. Acceptance criteria
- [ ] Identical labels for identical inputs across UI + API; both tests pass.

## 14. Self-review
- [ ] Vectors cover both schemes + custom + removal
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- If a divergence is found, the backend is the source of truth — fix the client to match.
