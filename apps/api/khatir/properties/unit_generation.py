"""Pure, deterministic unit-label generation (T-004 §2, §15).

The server is the authoritative source of truth for the wizard's unit step. The
Flutter UI (T-011) mirrors this exact logic, and T-014 asserts parity against the
same vectors — so this function must stay **pure** (no I/O, no Django, no model
access) and deterministic.

Algorithm (matches ``unitLabels()`` in ``proto/screens-landlord.js``)
---------------------------------------------------------------------
For each floor ``f`` in ``1..floors`` and each slot ``p`` in ``0..per_floor-1``:

- ``LETTER`` scheme → ``f`` followed by ``A, B, C…`` (``1A, 1B, 2A, 2B``).
- ``NUMBER`` scheme → ``f * 100 + (p + 1)`` (``101, 102, 201, 202``).

Then the ``custom`` labels are appended in order, and finally any label present
in ``removed`` is filtered out. Order is preserved and duplicates are collapsed
(first occurrence wins) so the result is a stable, de-duplicated list.
"""

from __future__ import annotations

from collections.abc import Iterable, Sequence

from .enums import UnitScheme


def _slot_label(floor: int, slot: int, scheme: str) -> str:
    """Label for one floor/slot pair under ``scheme`` (slot is 0-indexed)."""
    if scheme == UnitScheme.NUMBER:
        return str(floor * 100 + (slot + 1))
    # LETTER: floor number + A, B, C… for each slot on that floor.
    return f"{floor}{chr(ord('A') + slot)}"


def generate_unit_labels(
    *,
    floors: int,
    per_floor: int,
    scheme: str,
    custom: Sequence[str] | None = None,
    removed: Iterable[str] | None = None,
) -> list[str]:
    """Return the ordered, de-duplicated unit labels for a building.

    ``floors`` × ``per_floor`` generated labels, plus ``custom`` labels appended
    in order, minus anything in ``removed``. Pure and deterministic — the UI
    (T-011) and the parity test (T-014) rely on identical output.
    """
    removed_set = set(removed or ())
    labels: list[str] = []
    for floor in range(1, floors + 1):
        for slot in range(per_floor):
            labels.append(_slot_label(floor, slot, scheme))
    labels.extend(custom or ())

    seen: set[str] = set()
    result: list[str] = []
    for label in labels:
        if label in removed_set or label in seen:
            continue
        seen.add(label)
        result.append(label)
    return result
