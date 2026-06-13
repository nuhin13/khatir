// Cross-platform parity vectors for unit-label generation (T-014).
//
// These canonical input->output vectors are the shared contract between the
// Flutter client preview (`generateUnitLabels` in
// `features/properties/presentation/wizard/unit_label_gen.dart`) and the
// backend generator (`properties/unit_generation.py::generate_unit_labels`).
// The same five vectors are asserted by
// `apps/api/khatir/properties/tests/test_generation_parity.py` and documented
// in `docs/design/khatir-ui/UNIT_GENERATION.md`.
//
// If a divergence is ever found, the backend is the source of truth — fix the
// client to match (T-014 §15). Keep the vectors below identical to the Python
// test.
import 'package:flutter_test/flutter_test.dart';
import 'package:khatir_mobile/features/properties/data/models/property_enums.dart';
import 'package:khatir_mobile/features/properties/presentation/wizard/unit_label_gen.dart';

class _Vector {
  const _Vector({
    required this.floors,
    required this.perFloor,
    required this.scheme,
    required this.expected,
    this.custom = const [],
    this.removed = const {},
  });

  final int floors;
  final int perFloor;
  final UnitScheme scheme;
  final List<String> custom;
  final Set<String> removed;
  final List<String> expected;
}

// Mirrored verbatim from test_generation_parity.py and
// docs/design/khatir-ui/UNIT_GENERATION.md.
const _parityVectors = <_Vector>[
  _Vector(
    floors: 3,
    perFloor: 2,
    scheme: UnitScheme.letter,
    expected: ['1A', '1B', '2A', '2B', '3A', '3B'],
  ),
  _Vector(
    floors: 2,
    perFloor: 3,
    scheme: UnitScheme.number,
    expected: ['101', '102', '103', '201', '202', '203'],
  ),
  _Vector(
    floors: 2,
    perFloor: 2,
    scheme: UnitScheme.number,
    custom: ['2001'],
    expected: ['101', '102', '201', '202', '2001'],
  ),
  _Vector(
    floors: 2,
    perFloor: 2,
    scheme: UnitScheme.letter,
    removed: {'1B'},
    expected: ['1A', '2A', '2B'],
  ),
  _Vector(
    floors: 2,
    perFloor: 2,
    scheme: UnitScheme.number,
    custom: ['2001', 'GA'],
    removed: {'101', '202'},
    expected: ['102', '201', '2001', 'GA'],
  ),
];

void main() {
  group('unit-label generation parity vectors (T-014)', () {
    for (var i = 0; i < _parityVectors.length; i++) {
      final v = _parityVectors[i];
      test('vector #${i + 1}: ${v.floors}x${v.perFloor} ${v.scheme.name}', () {
        expect(
          generateUnitLabels(
            floors: v.floors,
            perFloor: v.perFloor,
            scheme: v.scheme,
            custom: v.custom,
            removed: v.removed,
          ),
          v.expected,
        );
      });
    }

    test('vectors cover both schemes + custom + removal', () {
      // T-014 §14 self-review.
      final schemes = _parityVectors.map((v) => v.scheme).toSet();
      expect(schemes, {UnitScheme.letter, UnitScheme.number});
      expect(_parityVectors.any((v) => v.custom.isNotEmpty), isTrue);
      expect(_parityVectors.any((v) => v.removed.isNotEmpty), isTrue);
    });
  });
}
