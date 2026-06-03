"""Vectors for the pure unit-label generator (T-004 §12, §15).

These are the canonical vectors T-014 asserts UI parity against, so they double
as the cross-platform contract. No Django, no DB — the function under test is
pure.
"""

from __future__ import annotations

import pytest

from khatir.properties.enums import UnitScheme
from khatir.properties.unit_generation import generate_unit_labels


def test_generate_letter() -> None:
    labels = generate_unit_labels(
        floors=3, per_floor=2, scheme=UnitScheme.LETTER
    )
    assert labels == ["1A", "1B", "2A", "2B", "3A", "3B"]


def test_generate_number() -> None:
    labels = generate_unit_labels(
        floors=3, per_floor=2, scheme=UnitScheme.NUMBER
    )
    assert labels == ["101", "102", "201", "202", "301", "302"]


def test_generate_letter_three_per_floor() -> None:
    labels = generate_unit_labels(
        floors=2, per_floor=3, scheme=UnitScheme.LETTER
    )
    assert labels == ["1A", "1B", "1C", "2A", "2B", "2C"]


def test_generate_with_custom() -> None:
    labels = generate_unit_labels(
        floors=2,
        per_floor=2,
        scheme=UnitScheme.NUMBER,
        custom=["2001", "GA"],
    )
    assert labels == ["101", "102", "201", "202", "2001", "GA"]


def test_generate_with_removed() -> None:
    labels = generate_unit_labels(
        floors=2,
        per_floor=2,
        scheme=UnitScheme.LETTER,
        removed=["1B", "2A"],
    )
    assert labels == ["1A", "2B"]


def test_generate_with_custom_and_removed() -> None:
    labels = generate_unit_labels(
        floors=2,
        per_floor=2,
        scheme=UnitScheme.NUMBER,
        custom=["2001"],
        removed=["101", "202"],
    )
    assert labels == ["102", "201", "2001"]


def test_generate_dedupes_custom_overlap() -> None:
    # A custom label colliding with a generated one is collapsed (first wins).
    labels = generate_unit_labels(
        floors=1, per_floor=2, scheme=UnitScheme.LETTER, custom=["1A", "9Z"]
    )
    assert labels == ["1A", "1B", "9Z"]


def test_generate_single_floor_single_unit() -> None:
    assert generate_unit_labels(
        floors=1, per_floor=1, scheme=UnitScheme.LETTER
    ) == ["1A"]
    assert generate_unit_labels(
        floors=1, per_floor=1, scheme=UnitScheme.NUMBER
    ) == ["101"]


def test_generate_is_pure_and_deterministic() -> None:
    # Same inputs → identical output, and no input mutation.
    custom = ["X1"]
    removed = ["1A"]
    first = generate_unit_labels(
        floors=2, per_floor=2, scheme=UnitScheme.LETTER, custom=custom, removed=removed
    )
    second = generate_unit_labels(
        floors=2, per_floor=2, scheme=UnitScheme.LETTER, custom=custom, removed=removed
    )
    assert first == second
    assert custom == ["X1"]
    assert removed == ["1A"]


@pytest.mark.parametrize(
    ("floors", "per_floor", "scheme", "expected"),
    [
        (4, 2, UnitScheme.LETTER, ["1A", "1B", "2A", "2B", "3A", "3B", "4A", "4B"]),
        (3, 2, UnitScheme.NUMBER, ["101", "102", "201", "202", "301", "302"]),
    ],
)
def test_generate_portfolio_seed_vectors(
    floors: int, per_floor: int, scheme: str, expected: list[str]
) -> None:
    # Mirrors the seed buildings rendered in proto/screens-landlord.js.
    assert (
        generate_unit_labels(floors=floors, per_floor=per_floor, scheme=scheme)
        == expected
    )
