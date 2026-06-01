"""Fernet-based field encryption + a masking helper.

Keyed by the ``FIELD_ENCRYPTION_KEY`` env var (a urlsafe-base64 Fernet key).
Used for personal/sensitive fields (NID numbers, etc.). Never log decrypted
values (``04_coding_conventions.md`` §10).
"""

from __future__ import annotations

from functools import lru_cache

from cryptography.fernet import Fernet, InvalidToken
from django.conf import settings
from django.core.exceptions import ImproperlyConfigured


@lru_cache(maxsize=1)
def _fernet() -> Fernet:
    key = getattr(settings, "FIELD_ENCRYPTION_KEY", None)
    if not key:
        raise ImproperlyConfigured(
            "FIELD_ENCRYPTION_KEY must be set to a urlsafe-base64 Fernet key."
        )
    if isinstance(key, str):
        key = key.encode("utf-8")
    try:
        return Fernet(key)
    except (ValueError, TypeError) as exc:  # pragma: no cover - config error path
        raise ImproperlyConfigured(
            f"FIELD_ENCRYPTION_KEY is not a valid Fernet key: {exc}"
        ) from exc


def encrypt(value: str) -> str:
    """Encrypt a plaintext string, returning urlsafe-base64 ciphertext."""
    return _fernet().encrypt(value.encode("utf-8")).decode("utf-8")


def decrypt(token: str) -> str:
    """Decrypt a token produced by :func:`encrypt`.

    Raises :class:`cryptography.fernet.InvalidToken` on tamper/wrong key.
    """
    return _fernet().decrypt(token.encode("utf-8")).decode("utf-8")


def mask(value: str, *, visible: int = 4, mask_char: str = "*") -> str:
    """Mask all but the last ``visible`` characters (e.g. ``nid=****7788``).

    Strings shorter than ``visible`` are fully masked.
    """
    if not value:
        return ""
    if len(value) <= visible:
        return mask_char * len(value)
    return mask_char * (len(value) - visible) + value[-visible:]


__all__ = ["encrypt", "decrypt", "mask", "InvalidToken"]
