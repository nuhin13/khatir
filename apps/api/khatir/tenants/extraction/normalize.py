"""Field normalizers shared by the OCR/ASR providers (T-004 §2).

Small, pure helpers that coerce the loose, provider-specific values into the
types :class:`~khatir.tenants.extraction.dto.ExtractedTenant` promises — so a
caller never sees a stray ``""`` vs ``None`` or an un-parsed date regardless of
which provider ran. Anything unparseable becomes ``None`` rather than raising,
because extraction is best-effort and the result is reviewed before save.
"""

from __future__ import annotations

import re
from datetime import date, datetime
from typing import Any

# Accepted date inputs from providers, tried in order.
_DATE_FORMATS = ("%Y-%m-%d", "%d-%m-%Y", "%d/%m/%Y", "%d %b %Y", "%d %B %Y")


def normalize_text(value: Any) -> str | None:
    """Strip surrounding whitespace; empty/non-str -> ``None``."""
    if not isinstance(value, str):
        return None
    cleaned = value.strip()
    return cleaned or None


def normalize_nid(value: Any) -> str | None:
    """Keep only digits from an NID string; empty -> ``None``.

    Never logged or persisted raw — returned for one-time review/encryption.
    """
    if value is None:
        return None
    digits = re.sub(r"\D", "", str(value))
    return digits or None


def normalize_date(value: Any) -> date | None:
    """Coerce a provider date (``date`` or string) to a :class:`date`.

    Tries a small set of common formats; returns ``None`` on anything it can't
    parse rather than raising.
    """
    if isinstance(value, date):
        return value
    if not isinstance(value, str):
        return None
    raw = value.strip()
    if not raw:
        return None
    for fmt in _DATE_FORMATS:
        try:
            return datetime.strptime(raw, fmt).date()
        except ValueError:
            continue
    return None
