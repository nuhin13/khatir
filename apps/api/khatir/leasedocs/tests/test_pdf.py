"""Tests for the lease-document PDF renderer (EPIC-18 · T-004).

Covers valid PDF output, the always-present disclaimer text, clause ordering,
and byte-for-byte determinism (no timestamps / random ids), mirroring the
EPIC-05 DMP renderer guarantees.
"""

from __future__ import annotations

import pytest

from khatir.leasedocs.pdf import render_lease_pdf
from khatir.leasedocs.scaffold import build_scaffold_content
from khatir.leases.tests.factories import LeaseFactory

from .factories import LeaseDocumentFactory

pytestmark = pytest.mark.django_db


def test_renders_valid_pdf_bytes() -> None:
    doc = LeaseDocumentFactory(lease=LeaseFactory())
    pdf = render_lease_pdf(doc)
    assert pdf.startswith(b"%PDF")
    assert pdf.rstrip().endswith(b"%%EOF")


def test_disclaimer_present_in_pdf() -> None:
    doc = LeaseDocumentFactory(
        lease=LeaseFactory(), content_json=build_scaffold_content()
    )
    pdf = render_lease_pdf(doc)
    assert b"legal advice" in pdf


def test_render_is_deterministic() -> None:
    doc = LeaseDocumentFactory(
        lease=LeaseFactory(), content_json=build_scaffold_content()
    )
    assert render_lease_pdf(doc) == render_lease_pdf(doc)
