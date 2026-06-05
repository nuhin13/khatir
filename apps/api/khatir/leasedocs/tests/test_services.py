"""Tests for the AI lease generation service (EPIC-18 · T-003).

The AI gateway is mocked at the ``call_gateway`` boundary so these tests are
hermetic and never open a socket. They cover the prompt build, clause parsing,
the required-clause guarantee (scaffold fallback), and the persisted draft.
"""

from __future__ import annotations

from typing import Any
from unittest import mock

import pytest

from khatir.ai_providers.client import AIGatewayError, AIGatewayResult
from khatir.ai_providers.enums import AICategory
from khatir.leasedocs.enums import LeaseDocumentClauseKey, LeaseDocumentStatus
from khatir.leasedocs.models import REQUIRED_CLAUSE_KEYS, LeaseDocument
from khatir.leasedocs.scaffold import (
    DEFAULT_DISCLAIMER_EN,
    SCAFFOLD_BY_KEY,
)
from khatir.leasedocs.services import (
    build_lease_prompt,
    generate_lease_document,
)
from khatir.leases.tests.factories import LeaseFactory

pytestmark = pytest.mark.django_db

_SERVICE_CALL = "khatir.leasedocs.services.call_gateway"


def _result(clauses: dict[str, Any], *, model_name: str = "khatir-lease-v1") -> AIGatewayResult:
    return AIGatewayResult.from_response(
        {"data": {"clauses": clauses}, "model_name": model_name, "provider_key": "openai"}
    )


# --- prompt build ------------------------------------------------------------


def test_build_prompt_carries_lease_facts_and_scaffold() -> None:
    lease = LeaseFactory()
    payload = build_lease_prompt(lease)

    assert payload["category"] == AICategory.LEASE.value
    facts = payload["facts"]
    assert facts["tenant_name"] == lease.tenant.name
    assert facts["landlord_name"] == lease.landlord.name
    assert facts["rent_amount"] == str(lease.rent)
    assert facts["advance_amount"] == str(lease.advance)
    assert facts["start_date"] == lease.start_date.isoformat()
    assert facts["end_date"] == lease.end_date.isoformat()
    # Premises is assembled from building/unit/address.
    assert lease.unit.building.name in facts["premises_address"]
    # The scaffold (clause keys) travels with the prompt.
    assert set(payload["scaffold"]) == set(SCAFFOLD_BY_KEY)


# --- happy path --------------------------------------------------------------


def test_generate_calls_gateway_for_lease_category_and_stores_draft() -> None:
    lease = LeaseFactory()
    full = {
        key: {**SCAFFOLD_BY_KEY[key], "body": f"AI body for {key}"}
        for key in SCAFFOLD_BY_KEY
    }
    with mock.patch(_SERVICE_CALL, return_value=_result(full)) as called:
        doc = generate_lease_document(lease)

    # Gateway invoked once for the LEASE category.
    assert called.call_count == 1
    assert called.call_args.args[0] == AICategory.LEASE

    assert isinstance(doc, LeaseDocument)
    assert doc.pk is not None
    assert doc.status == LeaseDocumentStatus.DRAFT
    assert doc.model_used == "khatir-lease-v1"
    assert doc.generated_at is not None
    assert doc.generated_by == lease.landlord
    assert doc.content_json[LeaseDocumentClauseKey.RENT]["body"] == "AI body for rent"
    assert doc.missing_required_clauses() == []


def test_generate_wraps_bare_string_clause_bodies() -> None:
    lease = LeaseFactory()
    clauses = {key: f"body {key}" for key in REQUIRED_CLAUSE_KEYS}
    with mock.patch(_SERVICE_CALL, return_value=_result(clauses)):
        doc = generate_lease_document(lease)

    rent = doc.content_json[LeaseDocumentClauseKey.RENT]
    assert rent["body"] == "body rent"
    # Title/order come from the scaffold when only a bare string was returned.
    assert rent["title_en"] == SCAFFOLD_BY_KEY[LeaseDocumentClauseKey.RENT]["title_en"]


# --- required-clause guarantee (scaffold fallback) ---------------------------


def test_generate_backfills_omitted_required_clauses_from_scaffold() -> None:
    lease = LeaseFactory()
    # AI returns everything EXCEPT the disclaimer and the rent clause.
    full = {
        key: {**SCAFFOLD_BY_KEY[key], "body": f"AI body for {key}"}
        for key in SCAFFOLD_BY_KEY
        if key not in (LeaseDocumentClauseKey.DISCLAIMER, LeaseDocumentClauseKey.RENT)
    }
    with mock.patch(_SERVICE_CALL, return_value=_result(full)):
        doc = generate_lease_document(lease)

    # Required clauses are all present after back-fill.
    assert doc.missing_required_clauses() == []
    # The omitted clauses fall back to the scaffold placeholder bodies.
    disclaimer = doc.content_json[LeaseDocumentClauseKey.DISCLAIMER]
    assert DEFAULT_DISCLAIMER_EN in disclaimer["body"]
    rent = doc.content_json[LeaseDocumentClauseKey.RENT]
    assert rent["body"] == SCAFFOLD_BY_KEY[LeaseDocumentClauseKey.RENT]["body"]


def test_generate_with_empty_gateway_data_yields_full_scaffold() -> None:
    lease = LeaseFactory()
    with mock.patch(_SERVICE_CALL, return_value=AIGatewayResult.from_response({"data": {}})):
        doc = generate_lease_document(lease)

    assert doc.missing_required_clauses() == []
    # Disclaimer always present even when the AI returned nothing usable.
    assert DEFAULT_DISCLAIMER_EN in doc.content_json[LeaseDocumentClauseKey.DISCLAIMER]["body"]


def test_generate_tolerates_clause_map_at_top_level() -> None:
    lease = LeaseFactory()
    # Some gateways may return the clause map directly under ``data``.
    clauses = {key: f"top {key}" for key in REQUIRED_CLAUSE_KEYS}
    result = AIGatewayResult.from_response({"data": clauses, "model_name": "m"})
    with mock.patch(_SERVICE_CALL, return_value=result):
        doc = generate_lease_document(lease)
    assert doc.content_json[LeaseDocumentClauseKey.PARTIES]["body"] == "top parties"


# --- audit / generated_by ----------------------------------------------------


def test_generate_records_explicit_generated_by() -> None:
    lease = LeaseFactory()
    other = lease.landlord  # any user; reuse to avoid extra factory wiring
    with mock.patch(_SERVICE_CALL, return_value=AIGatewayResult.from_response({"data": {}})):
        doc = generate_lease_document(lease, generated_by=other)
    assert doc.generated_by == other


# --- failure propagation -----------------------------------------------------


def test_gateway_error_propagates_and_writes_no_document() -> None:
    lease = LeaseFactory()
    with mock.patch(_SERVICE_CALL, side_effect=AIGatewayError("down")):
        with pytest.raises(AIGatewayError, match="down"):
            generate_lease_document(lease)
    # Transaction rolled back: no draft persisted.
    assert not LeaseDocument.objects.filter(lease=lease).exists()
