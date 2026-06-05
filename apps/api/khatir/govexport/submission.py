"""Pluggable government-submission adapter (EPIC-26 T-003 §1).

A gov-export package (built by :mod:`khatir.govexport.builder`, T-002) may either
just be *produced* for the landlord to download and file manually, or *submitted*
electronically to a government authority's intake endpoint. Whether a real
electronic channel exists varies by jurisdiction and is not part of the MVP, so
the submission step is modelled as a **pluggable adapter** behind one contract::

    GovSubmissionAdapter.submit(package) -> SubmissionResult

The default implementation (:class:`ProducePackageOnlyAdapter`) performs **no
real submission**: it records that the package was produced and is ready for
manual filing, returning a ``not_submitted`` result. A real gov-endpoint adapter
(HTTP intake, SFTP drop, etc.) can be registered later via :data:`_REGISTRY`
without changing any caller — callers always go through :func:`get_adapter` and
:meth:`GovSubmissionAdapter.submit`.

Design rules honoured here:

* **Off by default / no real call** — the default adapter never reaches a network,
  so the app is fully buildable and testable with no government account, mirroring
  the messaging :class:`ConsoleSender` default.
* **Pluggable** — the active adapter is config-driven
  (``gov_submission_adapter``, seeded OFF/``stub`` by T-005); callers never branch
  on the channel themselves.
* **Audited** — every submission attempt writes a ``govexport.submit`` audit row
  carrying only the outcome and the storage key, never raw PII payload.
* **Versioned result** — :class:`SubmissionResult` is a small, stable value object
  so a real adapter's reference / receipt can be threaded back to callers without
  changing the interface.
"""

from __future__ import annotations

import logging
from abc import ABC, abstractmethod
from collections.abc import Callable
from dataclasses import dataclass

from khatir.core.audit import audit
from khatir.core.config import get_config
from khatir.core.exceptions import ValidationError

from .builder import BuiltPackage
from .enums import GovExportStatus
from .models import GovExport

logger = logging.getLogger("khatir.govexport")

#: Config key naming the active submission adapter; default keeps the feature OFF.
ADAPTER_CONFIG_KEY = "gov_submission_adapter"

#: Default adapter name — produce-package-only, no real electronic submission.
DEFAULT_ADAPTER = "stub"


@dataclass(frozen=True)
class SubmissionResult:
    """Outcome of a submission attempt for one gov-export package.

    ``submitted`` is ``True`` only when a real authority intake accepted the
    package. The produce-package-only default always returns ``submitted=False``
    with ``status`` left at :attr:`GovExportStatus.GENERATED`. ``reference`` holds
    the authority's receipt / tracking id when a real adapter is plugged in;
    ``detail`` is a short human-readable note.
    """

    export_id: int
    submitted: bool
    status: GovExportStatus
    reference: str = ""
    detail: str = ""


class GovSubmissionAdapter(ABC):
    """Contract for submitting a built gov-export package to an authority.

    Implementations are submission-channel-specific (none today; a real HTTP/SFTP
    intake later) but the signature is uniform so callers never branch on the
    channel — they ask :func:`get_adapter` for an adapter and call :meth:`submit`.
    """

    #: Stable adapter name (matches its :data:`_REGISTRY` key); set per subclass.
    name: str

    @abstractmethod
    def submit(self, package: BuiltPackage) -> SubmissionResult:
        """Submit ``package`` to the authority and return the outcome.

        Implementations must be idempotent-friendly (a re-submit of an already
        produced package is safe) and must write a ``govexport.submit`` audit row.
        A real adapter raises
        :class:`~khatir.core.exceptions.UpstreamUnavailableError` on a transport
        failure so callers can retry; the default never calls out.
        """
        raise NotImplementedError


def _audit_submission(
    export: GovExport, *, submitted: bool, reference: str, detail: str
) -> None:
    """Write a ``govexport.submit`` audit row (outcome + storage key only)."""
    audit(
        actor=None,
        action="govexport.submit",
        target=export,
        before=None,
        after={
            "submitted": submitted,
            "status": export.status,
            "reference": reference,
            "detail": detail,
            "file_ref": export.file_ref,
        },
    )


class ProducePackageOnlyAdapter(GovSubmissionAdapter):
    """Default adapter: produce the package only — no real submission.

    The safe default. It performs no network call and does not mutate the
    export's :attr:`GovExportStatus` away from ``generated``: the package is left
    ready for the landlord to download and file manually. It still writes the
    ``govexport.submit`` audit row so the (no-op) attempt is traceable.
    """

    name = "stub"

    def submit(self, package: BuiltPackage) -> SubmissionResult:
        export = package.export
        detail = "Package produced for manual filing; no electronic submission performed."
        logger.info(
            "govexport stub submission for export %s (period %s): %s",
            export.pk,
            export.period,
            detail,
        )
        _audit_submission(export, submitted=False, reference="", detail=detail)
        return SubmissionResult(
            export_id=export.pk,
            submitted=False,
            status=GovExportStatus(export.status),
            reference="",
            detail=detail,
        )


#: Adapter name → constructor. Real channels register here without touching callers.
_REGISTRY: dict[str, Callable[[], GovSubmissionAdapter]] = {
    "stub": ProducePackageOnlyAdapter,
}


def get_adapter(name: str | None = None) -> GovSubmissionAdapter:
    """Return the submission adapter to use.

    * ``name`` given → the adapter registered under that name (explicit override).
    * ``name`` omitted → the adapter named by the ``gov_submission_adapter``
      config (seeded ``stub`` by T-005), defaulting to the produce-package-only
      stub so the feature stays OFF until a real adapter is configured.

    Raises :class:`~khatir.core.exceptions.ValidationError` for an unknown name.
    """
    if name is None:
        name = str(get_config(ADAPTER_CONFIG_KEY, DEFAULT_ADAPTER))
    try:
        return _REGISTRY[name]()
    except KeyError as exc:
        raise ValidationError(f"No gov-submission adapter named '{name}'.") from exc


def submit_package(package: BuiltPackage, *, adapter_name: str | None = None) -> SubmissionResult:
    """Submit a built ``package`` via the active (or named) adapter.

    Convenience wrapper so endpoint callers (T-004) need not resolve the adapter
    themselves: ``submit_package(built)``.
    """
    return get_adapter(adapter_name).submit(package)


__all__ = [
    "ADAPTER_CONFIG_KEY",
    "DEFAULT_ADAPTER",
    "GovSubmissionAdapter",
    "ProducePackageOnlyAdapter",
    "SubmissionResult",
    "get_adapter",
    "submit_package",
]
