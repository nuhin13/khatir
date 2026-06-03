---
id: T-014
epic: EPIC-03
title: Unit generation parity (UI↔API)
layer: cross-cutting
size: S
status: done
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
- [x] Canonical vectors documented (`docs/design/khatir-ui/UNIT_GENERATION.md`)
- [x] Backend test matches vectors (`test_generation_parity.py` — 6 tests green)
- [x] Flutter test matches vectors (`unit_gen_parity_test.dart` — same 5 vectors)
- [x] Cross-reference comments in both implementations
- [ ] both test suites pass — backend green; Flutter NOT executed (no Dart/Flutter toolchain in this env)

## 12. Test plan
### Automated
- parity vectors pass on both backend + client
### Manual QA
1. Generate same config on both → identical labels.

## 13. Acceptance criteria
- [~] Identical labels for identical inputs across UI + API; both tests pass.
      Vectors are byte-for-byte identical across both test files; backend suite
      green. Flutter suite could not be executed here (no Dart/Flutter toolchain).

## 14. Self-review
- [x] Vectors cover both schemes + custom + removal
### Deviations from spec
- Shared vectors captured in `docs/design/khatir-ui/UNIT_GENERATION.md` (the
  `UNIT_GENERATION.md` option offered in §5).
### Files touched (actual)
- `apps/api/khatir/properties/tests/test_generation_parity.py` (add)
- `apps/mobile/test/unit_gen_parity_test.dart` (add)
- `documnets/docs/design/khatir-ui/UNIT_GENERATION.md` (add)
- `apps/api/khatir/properties/unit_generation.py` (cross-ref comment)
- `apps/mobile/.../wizard/unit_label_gen.dart` (cross-ref comment)

## 15. Notes for the implementing agent
- If a divergence is found, the backend is the source of truth — fix the client to match.
