"""Encrypted object-storage helper (EPIC-04 T-003).

Stores sensitive files (NID images, payment proofs, generated DMP PDFs) under
opaque, ``kind``-prefixed keys and hands back **signed** URLs for retrieval —
objects are encrypted at rest (S3 server-side encryption) and are never
public-readable.

Two backends share one public API:

* **S3 backend** (production): boto3 against an S3-compatible endpoint
  (``S3_*`` env). Objects are written with ``private`` ACL and a
  ``ServerSideEncryption`` header; retrieval is a presigned ``GetObject`` URL
  with a TTL. Activated whenever ``settings.S3_BUCKET`` is set.
* **Filesystem fallback** (dev/test): writes under
  ``settings.ENCRYPTED_STORAGE_ROOT`` (a non-public path) so the pipeline runs
  without a live bucket. Used when no bucket is configured.

The public surface is the seam EPIC-05 T-005 (PDFs) and EPIC-07 (payment
proofs) orchestrate against: :func:`store_encrypted`, :func:`signed_url`,
:func:`delete`.
"""

from __future__ import annotations

import secrets
from functools import lru_cache
from pathlib import Path
from typing import Any

from django.conf import settings
from django.core.exceptions import ImproperlyConfigured

# Allowed storage namespaces (keep keys grouped by sensitivity / lifecycle).
_KINDS = frozenset({"nid", "proof", "pdf", "visitor"})

# Signed-URL default lifetime (seconds). T-005 keeps PDF links modest (1h).
DEFAULT_TTL_SECONDS = 3600


def _bucket() -> str:
    """Return the configured S3 bucket name, or ``""`` for the FS fallback."""
    return getattr(settings, "S3_BUCKET", "") or ""


def _new_key(kind: str) -> str:
    if kind not in _KINDS:
        raise ValueError(
            f"unknown storage kind {kind!r}; expected one of {sorted(_KINDS)}"
        )
    token = secrets.token_urlsafe(24)
    return f"{kind}/{token}"


# ── S3 backend ─────────────────────────────────────────────────────────


@lru_cache(maxsize=1)
def _s3_client() -> Any:
    """Build (and cache) a boto3 S3 client from ``S3_*`` settings."""
    import boto3
    from botocore.config import Config

    endpoint = getattr(settings, "S3_ENDPOINT_URL", "") or None
    region = getattr(settings, "S3_REGION", "") or None
    return boto3.client(
        "s3",
        endpoint_url=endpoint,
        region_name=region,
        aws_access_key_id=getattr(settings, "S3_ACCESS_KEY", "") or None,
        aws_secret_access_key=getattr(settings, "S3_SECRET_KEY", "") or None,
        config=Config(signature_version="s3v4"),
    )


def _s3_store(data: bytes, key: str) -> str:
    sse = getattr(settings, "S3_SSE", "AES256") or "AES256"
    # ``private`` ACL + server-side encryption: never public-readable, encrypted
    # at rest. The object is referenced only by its opaque key thereafter.
    _s3_client().put_object(
        Bucket=_bucket(),
        Key=key,
        Body=data,
        ACL="private",
        ServerSideEncryption=sse,
    )
    return key


def _s3_signed_url(key: str, ttl: int) -> str:
    return _s3_client().generate_presigned_url(
        "get_object",
        Params={"Bucket": _bucket(), "Key": key},
        ExpiresIn=ttl,
    )


def _s3_delete(key: str) -> None:
    _s3_client().delete_object(Bucket=_bucket(), Key=key)


# ── Filesystem fallback ────────────────────────────────────────────────


def _root() -> Path:
    base = getattr(settings, "ENCRYPTED_STORAGE_ROOT", None) or getattr(
        settings, "MEDIA_ROOT", None
    )
    if not base:
        raise ImproperlyConfigured(
            "ENCRYPTED_STORAGE_ROOT or MEDIA_ROOT must be set for object storage."
        )
    return Path(base)


def _fs_store(data: bytes, key: str) -> str:
    path = _root() / key
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return key


def _fs_signed_url(key: str, ttl: int) -> str:
    base = getattr(settings, "ENCRYPTED_STORAGE_PUBLIC_BASE", "https://storage.local")
    sig = secrets.token_urlsafe(16)
    return f"{base.rstrip('/')}/{key}?ttl={ttl}&sig={sig}"


def _fs_delete(key: str) -> None:
    (_root() / key).unlink(missing_ok=True)


# ── Public API ─────────────────────────────────────────────────────────


def store_encrypted(data: bytes, *, kind: str) -> str:
    """Persist ``data`` encrypted-at-rest and return an opaque storage key.

    ``kind`` namespaces the key (``nid`` / ``proof`` / ``pdf``). The returned
    key is opaque and unguessable; it is never a public URL. On S3 the object is
    written ``private`` with server-side encryption.
    """
    key = _new_key(kind)
    if _bucket():
        return _s3_store(data, key)
    return _fs_store(data, key)


def signed_url(key: str, *, ttl: int = DEFAULT_TTL_SECONDS) -> str:
    """Return a time-limited signed URL for retrieving ``key``.

    The URL grants temporary read access only; the underlying object is never
    public-readable. ``ttl`` is the lifetime in seconds.
    """
    if _bucket():
        return _s3_signed_url(key, ttl)
    return _fs_signed_url(key, ttl)


def delete(key: str) -> None:
    """Delete the stored object for ``key`` (idempotent)."""
    if _bucket():
        _s3_delete(key)
        return
    _fs_delete(key)


__all__ = ["store_encrypted", "signed_url", "delete", "DEFAULT_TTL_SECONDS"]
