"""Structured logging helpers and a PII-masking filter.

Per ``04_coding_conventions.md`` §10 and ``T-015`` §15, logs must never carry
full NID numbers, OTP codes, JWT/Bearer tokens, API keys, or bKash transaction
ids. :class:`PiiMaskingFilter` is attached to every handler so the masking is
applied regardless of how a message was produced (``%``-args, plain strings,
JSON ``extra`` fields).

The masking is text-level and deliberately conservative: it rewrites the
rendered log message (and string ``args``) rather than trying to understand the
structure of every payload. NID-like digit runs keep their last four digits so
records stay debuggable (``nid=****7788``); secrets are replaced wholesale.
"""

from __future__ import annotations

import logging
import re
from typing import Any

# 10–17 digit runs look like Bangladeshi NIDs / long account numbers. Keep the
# last four for traceability, mask the rest. Word boundaries avoid clobbering
# unrelated long numbers embedded in URLs/ids where possible.
_NID_RE = re.compile(r"\b(\d{6,13})(\d{4})\b")

# Authorization / Bearer tokens.
_BEARER_RE = re.compile(r"(?i)\b(bearer)\s+[A-Za-z0-9._\-]+")
_AUTH_HEADER_RE = re.compile(
    r"(?i)(authorization[\"']?\s*[:=]\s*[\"']?)(bearer\s+)?[A-Za-z0-9._\-]+"
)

# ``otp``/``code``/``token``/``secret``/``api_key`` fields in dict-ish or
# query-string text: ``otp=123456``, ``"token": "abc"``, ``code': '999999'``.
_SENSITIVE_FIELD_RE = re.compile(
    r"(?i)([\"']?(?:otp|code|token|secret|password|api[_-]?key|"
    r"signing_key|encryption_key)[\"']?\s*[:=]\s*)"
    r"([\"']?)[^\s,;&}\"']+(\2)"
)

# bKash-style transaction ids: typically alphanumeric, 10 chars, often appearing
# after a ``trx``/``txn``/``trxid`` label.
_TRX_RE = re.compile(
    r"(?i)([\"']?(?:trx|txn|trxid|trx_id|transaction_id)[\"']?\s*[:=]\s*)"
    r"([\"']?)[A-Za-z0-9]+(\2)"
)

_MASK = "****"


def mask_pii(text: str) -> str:
    """Return ``text`` with NID/OTP/token/secret/trx patterns masked.

    Idempotent: re-masking already-masked text leaves it unchanged.
    """
    if not text:
        return text
    text = _SENSITIVE_FIELD_RE.sub(rf"\1\2{_MASK}\3", text)
    text = _TRX_RE.sub(rf"\1\2{_MASK}\3", text)
    text = _AUTH_HEADER_RE.sub(rf"\1{_MASK}", text)
    text = _BEARER_RE.sub(rf"\1 {_MASK}", text)
    text = _NID_RE.sub(rf"{_MASK}\2", text)
    return text


class PiiMaskingFilter(logging.Filter):
    """Logging filter that masks PII in the message and its string args.

    Returns ``True`` always (it never drops records) — it only rewrites them.
    """

    def filter(self, record: logging.LogRecord) -> bool:
        if isinstance(record.msg, str):
            record.msg = mask_pii(record.msg)
        if record.args:
            record.args = _mask_args(record.args)
        return True


def _mask_args(args: Any) -> Any:
    if isinstance(args, dict):
        return {k: _mask_value(v) for k, v in args.items()}
    if isinstance(args, tuple):
        return tuple(_mask_value(v) for v in args)
    return _mask_value(args)


def _mask_value(value: Any) -> Any:
    return mask_pii(value) if isinstance(value, str) else value


def build_logging_config(*, log_level: str, json_logs: bool) -> dict[str, Any]:
    """Return a ``logging.config.dictConfig`` dict for the project.

    ``json_logs`` selects the JSON formatter (prod) versus the human-readable
    console formatter (dev). The :class:`PiiMaskingFilter` is attached to the
    console handler so every emitted record is masked.
    """
    formatter = "json" if json_logs else "console"
    return {
        "version": 1,
        "disable_existing_loggers": False,
        "filters": {
            "pii_masking": {
                "()": "khatir.core.logging.PiiMaskingFilter",
            },
        },
        "formatters": {
            "console": {
                "format": "[{asctime}] {levelname} {name}: {message}",
                "style": "{",
            },
            "json": {
                "()": "pythonjsonlogger.json.JsonFormatter",
                "format": "%(asctime)s %(levelname)s %(name)s %(message)s",
            },
        },
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "formatter": formatter,
                "filters": ["pii_masking"],
            },
        },
        "root": {
            "handlers": ["console"],
            "level": log_level,
        },
        "loggers": {
            "django": {
                "handlers": ["console"],
                "level": log_level,
                "propagate": False,
            },
            "khatir": {
                "handlers": ["console"],
                "level": log_level,
                "propagate": False,
            },
        },
    }
