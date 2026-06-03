"""Cross-platform parity vectors for unit-label generation (T-014).

These canonical input→output vectors are the shared contract between the
backend generator (``properties/unit_generation.py::generate_unit_labels``) and
the Flutter client preview
(``features/properties/presentation/wizard/unit_label_gen.dart::generateUnitLabels``).
The same five vectors are asserted by ``apps/mobile/test/unit_gen_parity_test.dart``
and documented in ``docs/design/khatir-ui/UNIT_GENERATION.md``.

If a divergence is ever found, the backend is the source of truth — fix the
client to match (T-014 §15). Keep the vectors below identical to the Dart test.
"""

from __future__ import annotations

import pytest

from khatir.properties.enums import UnitScheme
from khatir.properties.unit_generation import generate_unit_labels

# (floors, per_floor, scheme, custom, removed, expected) — mirrored verbatim in
# unit_gen_parity_test.dart and docs/design/khatir-ui/UNIT_GENERATION.md.
PARITY_VECTORS = [
    (3, 2, UnitScheme.LETTER, [], [], ["1A", "1B", "2A", "2B", "3A", "3B"]),
    (2, 3, UnitScheme.NUMBER, [], [], ["101", "102", "103", "201", "202", "203"]),
    (2, 2, UnitScheme.NUMBER, ["2001"], [], ["101", "102", "201", "202", "2001"]),
    (2, 2, UnitScheme.LETTER, [], ["1B"], ["1A", "2A", "2B"]),
    (
        2,
        2,
        UnitScheme.NUMBER,
        ["2001", "GA"],
        ["101", "202"],
        ["102", "201", "2001", "GA"],
    ),
]


@pytest.mark.parametrize(
    ("floors", "per_floor", "scheme", "custom", "removed", "expected"),
    PARITY_VECTORS,
)
def test_parity_vectors(
    floors: int,
    per_floor: int,
    scheme: str,
    custom: list[str],
    removed: list[str],
    expected: list[str],
) -> None:
    assert (
        generate_unit_labels(
            floors=floors,
            per_floor=per_floor,
            scheme=scheme,
            custom=custom,
            removed=removed,
        )
        == expected
    )


def test_vectors_cover_both_schemes_custom_and_removal() -> None:
    # T-014 §14 self-review: vectors must cover both schemes + custom + removal.
    schemes = {v[2] for v in PARITY_VECTORS}
    assert schemes == {UnitScheme.LETTER, UnitScheme.NUMBER}
    assert any(v[3] for v in PARITY_VECTORS)  # at least one custom
    assert any(v[4] for v in PARITY_VECTORS)  # at least one removal
