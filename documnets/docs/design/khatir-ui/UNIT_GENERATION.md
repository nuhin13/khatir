# Unit-label generation — shared parity contract (T-014)

The wizard's live unit preview (Flutter) and the bulk-generate endpoint
(backend) MUST produce **byte-for-byte identical** labels for identical inputs,
so what the user previews is exactly what gets saved.

This document is the single source of canonical input→output vectors that both
sides assert against:

- Backend: `apps/api/khatir/properties/tests/test_generation_parity.py`
  exercising `properties/unit_generation.py::generate_unit_labels`.
- Flutter: `apps/mobile/test/unit_gen_parity_test.dart`
  exercising `features/properties/presentation/wizard/unit_label_gen.dart::generateUnitLabels`.

Both mirror the prototype's `unitLabels()` in `proto/screens-landlord.js`.

## Algorithm

For each floor `f` in `1..floors` and each slot `p` in `0..perFloor-1`:

- `letter` scheme → `f` followed by `A, B, C…` (`1A, 1B, 2A, 2B`).
- `number` scheme → `f * 100 + (p + 1)` (`101, 102, 201, 202`).

Then `custom` labels are appended in order, and finally any label present in
`removed` is filtered out. Order is preserved and duplicates collapse (first
occurrence wins) so the result is a stable, de-duplicated list.

## Canonical vectors

| # | floors | perFloor | scheme | custom        | removed       | expected                                  |
|---|--------|----------|--------|---------------|---------------|-------------------------------------------|
| 1 | 3      | 2        | letter | —             | —             | `1A 1B 2A 2B 3A 3B`                       |
| 2 | 2      | 3        | number | —             | —             | `101 102 103 201 202 203`                 |
| 3 | 2      | 2        | number | `2001`        | —             | `101 102 201 202 2001`                    |
| 4 | 2      | 2        | letter | —             | `1B`          | `1A 2A 2B`                                |
| 5 | 2      | 2        | number | `2001`, `GA`  | `101`, `202`  | `102 201 2001 GA`                         |

Vectors cover both schemes (`letter` + `number`), a custom label, and a
removal — matching T-014 §14 self-review.

## Divergence policy (T-014 §15)

If the two implementations ever disagree, the **backend is the source of
truth** — fix the client to match.
