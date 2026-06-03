import '../../data/models/property_enums.dart';

/// Pure, deterministic unit-label generation — the client mirror of the
/// authoritative backend function (`properties/unit_generation.py`,
/// `generate_unit_labels`) and the prototype's `unitLabels()` in
/// `proto/screens-landlord.js`.
///
/// The server is the source of truth for the wizard's unit step; this function
/// only drives the live preview so the user sees exactly what `POST
/// /buildings/{id}/units/generate` will create. Because of that, the algorithm
/// must stay **pure** (no I/O, no Flutter) and byte-for-byte identical to the
/// backend — EPIC-03/T-014 asserts parity against the shared vectors in
/// `docs/design/khatir-ui/UNIT_GENERATION.md` (see `unit_gen_parity_test.dart`
/// here and `tests/test_generation_parity.py` on the backend).
///
/// Algorithm
/// ---------
/// For each floor `f` in `1..floors` and each slot `p` in `0..perFloor-1`:
///   * [UnitScheme.letter] → `f` + `A, B, C…` (`1A, 1B, 2A, 2B`).
///   * [UnitScheme.number] → `f * 100 + (p + 1)` (`101, 102, 201, 202`).
/// Then [custom] labels are appended in order, and finally any label in
/// [removed] is filtered out. Order is preserved and duplicates collapse
/// (first occurrence wins) so the result is a stable, de-duplicated list.
List<String> generateUnitLabels({
  required int floors,
  required int perFloor,
  required UnitScheme scheme,
  List<String> custom = const [],
  Set<String> removed = const {},
}) {
  final labels = <String>[];
  for (var floor = 1; floor <= floors; floor++) {
    for (var slot = 0; slot < perFloor; slot++) {
      labels.add(_slotLabel(floor, slot, scheme));
    }
  }
  labels.addAll(custom);

  final seen = <String>{};
  final result = <String>[];
  for (final label in labels) {
    if (removed.contains(label) || seen.contains(label)) continue;
    seen.add(label);
    result.add(label);
  }
  return result;
}

/// Label for one floor/slot pair under [scheme] (slot is 0-indexed).
String _slotLabel(int floor, int slot, UnitScheme scheme) {
  if (scheme == UnitScheme.number) {
    return '${floor * 100 + (slot + 1)}';
  }
  // letter: floor number + A, B, C… for each slot on that floor.
  return '$floor${String.fromCharCode('A'.codeUnitAt(0) + slot)}';
}
