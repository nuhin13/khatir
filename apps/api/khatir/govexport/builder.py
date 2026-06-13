"""Government-submission export package builder (EPIC-26 T-002 §1).

This is the *pure builder* seam for the gov-export wedge. Given a landlord and a
period (``YYYY-MM``) it assembles one submission package:

    select consenting tenants (T-002 §6 — consent respected)
      → assemble each tenant's DMP data + render its PDF (reuse EPIC-05 T-002/T-003)
      → build a version-tagged, official-compatible structured data file
      → zip the structured file + PDFs deterministically
      → store the zip encrypted (EPIC-04 T-003)
      → record a ``GovExport`` ledger row + write an audit entry

Design rules honoured here:

* **Consent respected** — only tenants whose linked user account holds an
  active (granted, not revoked, not expired) ``pdpa_data_sharing`` consent are
  included. Tenants without a linked app-user account are *not* eligible (no
  consent could have been captured), so they are skipped.
* **Audited** — a ``govexport.generate`` audit row is written for every built
  package (no raw PII payload in the audit ``after`` snapshot — only counts and
  the storage key).
* **Versioned format** — the structured file carries a ``format_version`` and is
  also persisted onto the ``GovExport`` row, so format updates are tracked and
  re-runs are distinguishable.
* **Deterministic** — the same inputs produce byte-identical structured JSON and
  zip output (fixed member order, sorted keys, fixed zip timestamps), so the
  package is golden-testable.
* **No raw NID on the ledger / structured file** — the full NID is read only
  through the audited decrypt path in the EPIC-05 assembler and rendered only
  into the PDFs; the structured manifest carries the masked NID, never the
  plaintext.

The feature flag (``gov_export_enabled``, default OFF) is enforced at the
endpoint layer (EPIC-26 T-004/T-005); this builder is flag-agnostic so it stays
unit-testable in isolation.
"""

from __future__ import annotations

import io
import json
import zipfile
from dataclasses import dataclass
from datetime import datetime
from typing import Any

from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from khatir.compliance.enums import ConsentType
from khatir.compliance.models import ConsentRecord
from khatir.core import storage
from khatir.core.audit import audit
from khatir.core.config import get_config
from khatir.dmpforms.assembler import assemble_dmp_data
from khatir.dmpforms.pdf import render_dmp_pdf

from .enums import GovExportStatus
from .models import GovExport

# Active format/template version for the structured submission file. Config-driven
# (``gov_export_format_version`` is seeded by EPIC-26 T-005); this is the fallback
# until the SystemConfig row exists.
DEFAULT_FORMAT_VERSION = "2026.1"

# Signed-URL lifetime for a generated package download (modest, mirrors EPIC-05).
PACKAGE_URL_TTL_SECONDS = storage.DEFAULT_TTL_SECONDS

# Fixed timestamp for every zip member so packages are byte-deterministic
# (zip stores an mtime per entry; a wall-clock value would break golden tests).
_ZIP_EPOCH = (1980, 1, 1, 0, 0, 0)

# Name of the structured data file inside the package zip.
STRUCTURED_FILENAME = "submission.json"


@dataclass(frozen=True)
class BuiltPackage:
    """Result of building a package: the ledger row and a signed download URL."""

    export: GovExport
    signed_url: str
    zip_bytes: bytes


def _format_version() -> str:
    """The active gov-export format version (config-driven; T-005 seeds the row)."""
    return str(get_config("gov_export_format_version", DEFAULT_FORMAT_VERSION))


def _consenting_tenant_ids(tenant_ids: list[int]) -> set[int]:
    """Return the subset of ``tenant_ids`` whose linked user has live data-sharing consent.

    A tenant is eligible only if their ``linked_user`` holds a
    ``pdpa_data_sharing`` ``ConsentRecord`` that has been granted, not revoked,
    and not expired as of now. Tenants with no linked app-user account cannot
    have given consent and are therefore excluded.
    """
    from khatir.tenants.models import Tenant

    now = timezone.now()
    linked = dict(
        Tenant.objects.filter(pk__in=tenant_ids, linked_user__isnull=False).values_list(
            "pk", "linked_user_id"
        )
    )
    if not linked:
        return set()

    unexpired = Q(expires_at__isnull=True) | Q(expires_at__gt=now)
    consented_user_ids = set(
        ConsentRecord.objects.filter(
            unexpired,
            user_id__in=set(linked.values()),
            consent_type=ConsentType.PDPA_DATA_SHARING,
            revoked_at__isnull=True,
        ).values_list("user_id", flat=True)
    )
    return {tid for tid, uid in linked.items() if uid in consented_user_ids}


def _period_tenants(landlord: Any, period: str) -> list[Any]:
    """Tenants on the landlord's active leases that cover ``period`` (YYYY-MM).

    A lease covers the period when its ``start_date``..``end_date`` span includes
    any day of that month. Results are de-duplicated and ordered by tenant pk so
    the package is deterministic.
    """
    from khatir.leases.enums import LeaseStatus
    from khatir.leases.models import Lease

    year, month = (int(p) for p in period.split("-"))
    month_start = datetime(year, month, 1).date()
    # Last day of the month: first day of next month minus one day.
    if month == 12:
        next_month_start = datetime(year + 1, 1, 1).date()
    else:
        next_month_start = datetime(year, month + 1, 1).date()

    leases = (
        Lease.objects.filter(
            landlord=landlord,
            status=LeaseStatus.ACTIVE,
            start_date__lt=next_month_start,
            end_date__gte=month_start,
        )
        .select_related("tenant")
        .order_by("tenant_id")
    )

    seen: set[int] = set()
    tenants: list[Any] = []
    for lease in leases:
        if lease.tenant_id not in seen:
            seen.add(lease.tenant_id)
            tenants.append(lease.tenant)
    return tenants


def build_structured_data(
    *, landlord: Any, period: str, format_version: str, tenants: list[Any]
) -> dict[str, Any]:
    """Build the version-tagged, official-compatible structured submission dict.

    Carries only non-sensitive / masked identifiers — the full NID is never
    placed here (it lives only in the rendered PDFs via the audited decrypt path).
    Records are ordered by tenant pk for determinism.
    """
    records = [
        {
            "tenant_id": t.pk,
            "tenant_name": t.name,
            "nid_masked": getattr(t, "nid_number_masked", "") or "",
            "dob": t.dob.isoformat() if getattr(t, "dob", None) else "",
            "verification_status": getattr(t, "verification_status", "") or "",
        }
        for t in tenants
    ]
    return {
        "format_version": format_version,
        "period": period,
        "landlord_id": landlord.pk,
        "record_count": len(records),
        "records": records,
    }


def _structured_bytes(data: dict[str, Any]) -> bytes:
    """Serialise the structured dict to deterministic, sorted UTF-8 JSON bytes."""
    return json.dumps(data, sort_keys=True, ensure_ascii=False, indent=2).encode("utf-8")


def build_zip(structured: bytes, pdfs: list[tuple[str, bytes]]) -> bytes:
    """Zip the structured file + named PDFs into deterministic archive bytes.

    Every member uses a fixed timestamp and the members are written in a fixed
    order (structured file first, then PDFs in the given order) so identical
    inputs yield byte-identical archives.
    """
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        info = zipfile.ZipInfo(STRUCTURED_FILENAME, date_time=_ZIP_EPOCH)
        zf.writestr(info, structured)
        for name, payload in pdfs:
            pdf_info = zipfile.ZipInfo(name, date_time=_ZIP_EPOCH)
            zf.writestr(pdf_info, payload)
    return buffer.getvalue()


def build_export_package(*, landlord: Any, period: str, actor: Any | None = None) -> BuiltPackage:
    """Build, store, and record a gov-submission package for ``landlord`` + ``period``.

    Steps: select the landlord's consenting tenants for the period, assemble +
    render each DMP PDF, build the version-tagged structured file, zip it all
    deterministically, store the zip encrypted, persist a ``GovExport`` ledger
    row, and write a ``govexport.generate`` audit entry. Returns the ledger row,
    a signed download URL, and the raw zip bytes (handy for endpoint streaming /
    tests).

    ``period`` is ``YYYY-MM``. ``actor`` is the authenticated landlord/manager
    triggering the export; it is threaded into the audited NID decrypt path and
    recorded as the audit actor.
    """
    format_version = _format_version()

    candidates = _period_tenants(landlord, period)
    eligible_ids = _consenting_tenant_ids([t.pk for t in candidates])
    tenants = [t for t in candidates if t.pk in eligible_ids]

    pdfs: list[tuple[str, bytes]] = []
    for tenant in tenants:
        dmp_data = assemble_dmp_data(tenant, actor=actor)
        pdf_bytes = render_dmp_pdf(dmp_data, format_version)
        pdfs.append((f"dmp/tenant-{tenant.pk}.pdf", pdf_bytes))

    structured = _structured_bytes(
        build_structured_data(
            landlord=landlord, period=period, format_version=format_version, tenants=tenants
        )
    )
    zip_bytes = build_zip(structured, pdfs)
    file_ref = storage.store_encrypted(zip_bytes, kind="gov_export")

    with transaction.atomic():
        export = GovExport.objects.create(
            landlord=landlord,
            period=period,
            format_version=format_version,
            file_ref=file_ref,
            record_count=len(tenants),
            status=GovExportStatus.GENERATED,
        )

    audit(
        actor=actor,
        action="govexport.generate",
        target=export,
        before=None,
        after={
            "period": period,
            "format_version": format_version,
            "record_count": len(tenants),
            "file_ref": file_ref,
        },
    )

    url = storage.signed_url(file_ref, ttl=PACKAGE_URL_TTL_SECONDS)
    return BuiltPackage(export=export, signed_url=url, zip_bytes=zip_bytes)


def signed_url_for_export(export: GovExport, *, ttl: int = PACKAGE_URL_TTL_SECONDS) -> str:
    """Return a fresh signed download URL for an existing export's package."""
    return storage.signed_url(export.file_ref, ttl=ttl)


__all__ = [
    "build_export_package",
    "build_structured_data",
    "build_zip",
    "signed_url_for_export",
    "BuiltPackage",
    "DEFAULT_FORMAT_VERSION",
    "PACKAGE_URL_TTL_SECONDS",
    "STRUCTURED_FILENAME",
]
