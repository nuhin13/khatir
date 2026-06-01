"""DRF serializers for the auth endpoints (T-005 §3).

Input validation only — the zod-equivalent boundary. Bangladeshi phone numbers
must arrive in E.164 form (``+8801`` + 9 digits, 11 national digits total, see
``06_database_schema.md`` line 70). ``ValidationError`` raised here is mapped to
the ``validation_error`` envelope by ``core.exceptions.exception_handler``.
"""

from __future__ import annotations

import re

from rest_framework import serializers

# E.164 Bangladesh mobile: +880, leading 1, then 9 digits (e.g. +8801712345678).
_BD_PHONE_RE = re.compile(r"^\+8801\d{9}$")


def _validate_bd_phone(value: str) -> None:
    if not _BD_PHONE_RE.match(value):
        raise serializers.ValidationError(
            "Enter a valid Bangladeshi phone number in E.164 format (+8801XXXXXXXXX)."
        )


class RequestOtpSerializer(serializers.Serializer[dict[str, str]]):
    """Validates the ``request-otp`` body: a single E.164 BD phone."""

    phone = serializers.CharField(max_length=20, validators=[_validate_bd_phone])


class VerifyOtpSerializer(serializers.Serializer[dict[str, str]]):
    """Validates the ``verify-otp`` body: phone + the numeric code."""

    phone = serializers.CharField(max_length=20, validators=[_validate_bd_phone])
    code = serializers.CharField(max_length=12, min_length=1, trim_whitespace=True)
