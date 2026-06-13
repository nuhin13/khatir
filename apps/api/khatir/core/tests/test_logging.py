"""Tests for the PII-masking log filter (T-015 §12)."""

from __future__ import annotations

import logging

from khatir.core.logging import (
    PiiMaskingFilter,
    build_logging_config,
    mask_pii,
)


def test_masks_nid_keeping_last_four() -> None:
    masked = mask_pii("nid=1990123456788")
    assert "1990123456788" not in masked
    assert masked.endswith("6788")
    assert "****" in masked


def test_masks_bearer_token() -> None:
    masked = mask_pii("Authorization: Bearer abc.def.ghijkl")
    assert "abc.def.ghijkl" not in masked
    assert "****" in masked


def test_masks_otp_field() -> None:
    masked = mask_pii('{"otp": "123456"}')
    assert "123456" not in masked
    assert "****" in masked


def test_masks_token_and_secret_fields() -> None:
    masked = mask_pii("token=eyJhbGciOiJIUzI1 secret=topsecretvalue")
    assert "eyJhbGciOiJIUzI1" not in masked
    assert "topsecretvalue" not in masked


def test_masks_bkash_trx_id() -> None:
    masked = mask_pii("trxid=8N7A1B2C3D")
    assert "8N7A1B2C3D" not in masked
    assert "****" in masked


def test_mask_is_idempotent() -> None:
    once = mask_pii("nid=1990123456788 token=abcdef")
    assert mask_pii(once) == once


def test_filter_rewrites_record_message() -> None:
    record = logging.LogRecord(
        name="khatir.test",
        level=logging.INFO,
        pathname=__file__,
        lineno=1,
        msg="login otp=987654 for nid=1990123456788",
        args=None,
        exc_info=None,
    )
    assert PiiMaskingFilter().filter(record) is True
    assert "987654" not in record.getMessage()
    assert "1990123456788" not in record.getMessage()


def test_filter_masks_string_args() -> None:
    record = logging.LogRecord(
        name="khatir.test",
        level=logging.INFO,
        pathname=__file__,
        lineno=1,
        msg="value %s",
        args=("token=supersecretvalue",),
        exc_info=None,
    )
    PiiMaskingFilter().filter(record)
    assert "supersecretvalue" not in record.getMessage()


def test_build_logging_config_selects_formatter() -> None:
    json_cfg = build_logging_config(log_level="INFO", json_logs=True)
    assert json_cfg["handlers"]["console"]["formatter"] == "json"
    assert "pii_masking" in json_cfg["handlers"]["console"]["filters"]

    console_cfg = build_logging_config(log_level="DEBUG", json_logs=False)
    assert console_cfg["handlers"]["console"]["formatter"] == "console"
    assert console_cfg["root"]["level"] == "DEBUG"
