"""DMP PDF generation pipeline — orchestration (EPIC-05 T-005 §2).

``generate_dmp_pdf(tenant, actor)`` runs the full pipeline:

    assemble (T-002) → render (T-003) → store encrypted (EPIC-04 T-003)
    → create DMPFormRecord (T-001, with template_version) → return signed URL

Generation is synchronous (acceptable for a single form, T-005 §15) and audited
(``dmpform.generate``). The full NID lives server-side only — it never enters the
record, the response, or any log. Free-tier is allowed (no plan gate here).
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from django.db import transaction
from django.utils import timezone

from khatir.core import storage
from khatir.core.audit import audit
from khatir.core.config import get_config

from .assembler import assemble_dmp_data
from .models import DMPFormRecord
from .pdf import render_dmp_pdf

# Fallback used until T-006 seeds the ``dmp_template_version`` SystemConfig row.
DEFAULT_TEMPLATE_VERSION = "2026.1"

# Signed-URL lifetime for generated PDFs (modest, per T-005 §15).
PDF_URL_TTL_SECONDS = storage.DEFAULT_TTL_SECONDS


@dataclass(frozen=True)
class GeneratedDmp:
    """Result of a generation: the persisted record and a signed download URL."""

    record: DMPFormRecord
    signed_url: str


def _template_version() -> str:
    """The active DMP template version (config-driven; T-006 seeds the row)."""
    return str(get_config("dmp_template_version", DEFAULT_TEMPLATE_VERSION))


def generate_dmp_pdf(*, tenant: Any, actor: Any | None) -> GeneratedDmp:
    """Generate, store, and record a DMP PDF for ``tenant``; return a signed URL.

    ``actor`` is the authenticated user triggering generation (threaded into the
    audited NID decrypt and recorded as ``generated_by``). The PDF bytes are
    stored encrypted; only the opaque key is persisted on the record.
    """
    template_version = _template_version()

    dmp_data = assemble_dmp_data(tenant, actor=actor)
    pdf_bytes = render_dmp_pdf(dmp_data, template_version)
    pdf_ref = storage.store_encrypted(pdf_bytes, kind="pdf")

    with transaction.atomic():
        record = DMPFormRecord.objects.create(
            tenant=tenant,
            template_version=template_version,
            pdf_ref=pdf_ref,
            generated_by=actor if getattr(actor, "pk", None) else None,
            generated_at=timezone.now(),
        )

    audit(
        actor=actor,
        action="dmpform.generate",
        target=record,
        before=None,
        after={"template_version": template_version, "tenant_id": tenant.pk},
    )

    url = storage.signed_url(pdf_ref, ttl=PDF_URL_TTL_SECONDS)
    return GeneratedDmp(record=record, signed_url=url)


def signed_url_for_record(record: DMPFormRecord, *, ttl: int = PDF_URL_TTL_SECONDS) -> str:
    """Return a fresh signed download URL for an existing record's PDF."""
    return storage.signed_url(record.pdf_ref, ttl=ttl)


__all__ = [
    "generate_dmp_pdf",
    "signed_url_for_record",
    "GeneratedDmp",
    "DEFAULT_TEMPLATE_VERSION",
    "PDF_URL_TTL_SECONDS",
]
