"""Tests for the compliant base lease clause scaffold (EPIC-18 · T-002 §12)."""

from __future__ import annotations

from khatir.leasedocs.enums import LeaseDocumentClauseKey
from khatir.leasedocs.models import REQUIRED_CLAUSE_KEYS, LeaseDocument
from khatir.leasedocs.scaffold import (
    CLAUSE_SCAFFOLD,
    DEFAULT_DISCLAIMER_BN,
    DEFAULT_DISCLAIMER_EN,
    SCAFFOLD_BY_KEY,
    SCAFFOLD_CLAUSE_KEYS,
    build_scaffold_content,
    ensure_required_clauses,
)

# ---------------------------------------------------------------------------
# Scaffold shape & coverage
# ---------------------------------------------------------------------------


def test_scaffold_covers_all_epic_sections() -> None:
    """The base structure has every DNCC/DSCC-aware section from the epic goal."""
    expected = {
        "parties",
        "premises",
        "rent",
        "advance",
        "term",
        "obligations",
        "termination",
        "dispute",
        "disclaimer",
    }
    assert set(SCAFFOLD_CLAUSE_KEYS) == expected


def test_scaffold_keys_are_valid_enum_values() -> None:
    valid = {c.value for c in LeaseDocumentClauseKey}
    assert set(SCAFFOLD_CLAUSE_KEYS) <= valid


def test_required_clauses_are_subset_of_scaffold() -> None:
    assert set(REQUIRED_CLAUSE_KEYS) <= set(SCAFFOLD_CLAUSE_KEYS)


def test_every_required_clause_marked_required_in_scaffold() -> None:
    for key in REQUIRED_CLAUSE_KEYS:
        assert SCAFFOLD_BY_KEY[key]["required"] is True


def test_each_clause_has_bilingual_titles_and_body() -> None:
    for _key, spec in CLAUSE_SCAFFOLD:
        assert spec["title_en"].strip()
        assert spec["title_bn"].strip()
        assert spec["body"].strip()
        assert isinstance(spec["order"], int)


def test_disclaimer_is_bilingual_not_legal_advice() -> None:
    disclaimer = SCAFFOLD_BY_KEY["disclaimer"]
    assert "not constitute legal advice" in disclaimer["body"].lower()
    assert DEFAULT_DISCLAIMER_EN in disclaimer["body"]
    assert DEFAULT_DISCLAIMER_BN in disclaimer["body"]


def test_disclaimer_renders_last() -> None:
    orders = {key: spec["order"] for key, spec in CLAUSE_SCAFFOLD}
    assert orders["disclaimer"] == max(orders.values())


def test_clause_keys_are_unique() -> None:
    assert len(SCAFFOLD_CLAUSE_KEYS) == len(set(SCAFFOLD_CLAUSE_KEYS))


# ---------------------------------------------------------------------------
# build_scaffold_content
# ---------------------------------------------------------------------------


def test_build_scaffold_content_returns_all_clauses() -> None:
    content = build_scaffold_content()
    assert set(content) == set(SCAFFOLD_CLAUSE_KEYS)


def test_build_scaffold_content_is_independent_copy() -> None:
    a = build_scaffold_content()
    b = build_scaffold_content()
    a["rent"]["body"] = "mutated"
    assert b["rent"]["body"] != "mutated"
    # Source scaffold also untouched.
    assert SCAFFOLD_BY_KEY["rent"]["body"] != "mutated"


def test_built_scaffold_satisfies_required_clause_guarantee() -> None:
    """A fresh scaffold already passes the model's required-clause check."""
    doc = LeaseDocument(content_json=build_scaffold_content())
    assert doc.missing_required_clauses() == []


# ---------------------------------------------------------------------------
# ensure_required_clauses — the guarantee
# ---------------------------------------------------------------------------


def test_ensure_backfills_missing_required_clause() -> None:
    """AI dropped the disclaimer — scaffold must put it back."""
    partial = build_scaffold_content()
    del partial["disclaimer"]
    fixed = ensure_required_clauses(partial)
    assert "disclaimer" in fixed
    assert "not constitute legal advice" in fixed["disclaimer"]["body"].lower()


def test_ensure_backfills_all_when_empty() -> None:
    fixed = ensure_required_clauses({})
    assert set(SCAFFOLD_CLAUSE_KEYS) <= set(fixed)
    doc = LeaseDocument(content_json=fixed)
    assert doc.missing_required_clauses() == []


def test_ensure_handles_none() -> None:
    fixed = ensure_required_clauses(None)
    assert set(SCAFFOLD_CLAUSE_KEYS) <= set(fixed)


def test_ensure_preserves_ai_filled_bodies() -> None:
    ai = build_scaffold_content()
    ai["rent"]["body"] = "BDT 25,000 due on the 1st."
    fixed = ensure_required_clauses(ai)
    assert fixed["rent"]["body"] == "BDT 25,000 due on the 1st."


def test_ensure_replaces_empty_body_clause_with_scaffold() -> None:
    ai = build_scaffold_content()
    ai["term"]["body"] = "   "
    fixed = ensure_required_clauses(ai)
    assert fixed["term"]["body"] == SCAFFOLD_BY_KEY["term"]["body"]


def test_ensure_preserves_extra_caller_clauses() -> None:
    fixed = ensure_required_clauses({"custom_addendum": "Pets allowed."})
    assert fixed["custom_addendum"] == "Pets allowed."
    assert set(SCAFFOLD_CLAUSE_KEYS) <= set(fixed)


def test_ensure_orders_scaffold_clauses_first() -> None:
    fixed = ensure_required_clauses({"custom_addendum": "x"})
    keys = list(fixed)
    # All scaffold keys come before the caller-only key.
    assert keys[-1] == "custom_addendum"
    assert keys[: len(SCAFFOLD_CLAUSE_KEYS)] == list(SCAFFOLD_CLAUSE_KEYS)


def test_ensure_treats_string_clause_as_filled() -> None:
    """Legacy string-bodied clauses (T-001 shape) are preserved, not clobbered."""
    fixed = ensure_required_clauses({"rent": "BDT 10,000"})
    assert fixed["rent"] == "BDT 10,000"
