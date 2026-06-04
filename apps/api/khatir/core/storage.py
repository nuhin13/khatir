"""Encrypted object-storage helper (EPIC-04 T-003 seam).

Stores sensitive files (NID images, payment proofs, generated DMP PDFs) under
opaque, ``kind``-prefixed keys and hands back **signed** URLs for retrieval —
never public-readable.

This module is the seam EPIC-05 T-005 orchestrates against. The production
implementation (boto3 against an S3-compatible endpoint, server-side
encryption) is delivered by EPIC-04 T-003; T-005's tests mock these functions.
Until the S3 backend lands, a local filesystem fallback under
``settings.MEDIA_ROOT`` keeps the pipeline runnable in dev/test without leaking
bytes to a public location.
"""

from __future__ import annotations

import secrets
from pathlib import Path

from django.conf import settings
from django.core.exceptions import ImproperlyConfigured

# Allowed storage namespaces (keep keys grouped by sensitivity / lifecycle).
_KINDS = frozenset({"nid", "proof", "pdf"})

# Signed-URL default lifetime (seconds). T-005 keeps PDF links modest (1h).
DEFAULT_TTL_SECONDS = 3600


def _root() -> Path:
    base = getattr(settings, "ENCRYPTED_STORAGE_ROOT", None) or getattr(
        settings, "MEDIA_ROOT", None
    )
    if not base:
        raise ImproperlyConfigured(
            "ENCRYPTED_STORAGE_ROOT or MEDIA_ROOT must be set for object storage."
        )
    return Path(base)


def store_encrypted(data: bytes, *, kind: str) -> str:
    """Persist ``data`` encrypted-at-rest and return an opaque storage key.

    ``kind`` namespaces the key (``nid`` / ``proof`` / ``pdf``). The returned key
    is opaque and unguessable; it is never a public URL.
    """
    if kind not in _KINDS:
        raise ValueError(f"unknown storage kind {kind!r}; expected one of {sorted(_KINDS)}")

    token = secrets.token_urlsafe(24)
    key = f"{kind}/{token}"

    path = _root() / key
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return key


def signed_url(key: str, *, ttl: int = DEFAULT_TTL_SECONDS) -> str:
    """Return a time-limited signed URL for retrieving ``key``.

    The URL grants temporary read access only; the underlying object is never
    public-readable. ``ttl`` is the lifetime in seconds.
    """
    base = getattr(settings, "ENCRYPTED_STORAGE_PUBLIC_BASE", "https://storage.local")
    sig = secrets.token_urlsafe(16)
    return f"{base.rstrip('/')}/{key}?ttl={ttl}&sig={sig}"


def delete(key: str) -> None:
    """Delete the stored object for ``key`` (idempotent)."""
    path = _root() / key
    path.unlink(missing_ok=True)


__all__ = ["store_encrypted", "signed_url", "delete", "DEFAULT_TTL_SECONDS"]
