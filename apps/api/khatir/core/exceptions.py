"""Typed application exceptions + the DRF exception handler.

Every error response in the API has the shape (``04_coding_conventions.md`` §1)::

    {"error": {"code": "validation_error", "message": "...", "details": {...}}}

``code`` is always a stable machine string from ``ErrorCode``. Services raise the
typed exceptions below; the handler maps DRF/Django exceptions to the envelope.
"""

from __future__ import annotations

from typing import Any

from django.core.exceptions import PermissionDenied as DjangoPermissionDenied
from django.http import Http404
from rest_framework import status
from rest_framework.exceptions import APIException
from rest_framework.exceptions import ValidationError as DRFValidationError
from rest_framework.response import Response
from rest_framework.views import exception_handler as drf_exception_handler

from .enums import ErrorCode


class AppError(APIException):
    """Base class for typed application errors carrying an ``ErrorCode``.

    Subclasses set ``error_code``, ``status_code`` and a default message.
    ``details`` is an optional machine-readable payload (e.g. per-field errors).
    """

    error_code: ErrorCode = ErrorCode.SERVER_ERROR
    status_code: int = status.HTTP_500_INTERNAL_SERVER_ERROR
    default_detail = "An unexpected error occurred."

    def __init__(
        self,
        message: str | None = None,
        *,
        details: dict[str, Any] | None = None,
        code: ErrorCode | None = None,
    ) -> None:
        self.message = message or str(self.default_detail)
        self.details = details
        if code is not None:
            self.error_code = code
        super().__init__(detail=self.message, code=self.error_code.value)


class ValidationError(AppError):
    error_code = ErrorCode.VALIDATION_ERROR
    status_code = status.HTTP_400_BAD_REQUEST
    default_detail = "Validation failed."


class NotFoundError(AppError):
    error_code = ErrorCode.NOT_FOUND
    status_code = status.HTTP_404_NOT_FOUND
    default_detail = "Not found."


class PermissionDeniedError(AppError):
    error_code = ErrorCode.PERMISSION_DENIED
    status_code = status.HTTP_403_FORBIDDEN
    default_detail = "You do not have permission to perform this action."


class AuthRequiredError(AppError):
    error_code = ErrorCode.AUTH_REQUIRED
    status_code = status.HTTP_401_UNAUTHORIZED
    default_detail = "Authentication is required."


class AuthInvalidError(AppError):
    error_code = ErrorCode.AUTH_INVALID
    status_code = status.HTTP_401_UNAUTHORIZED
    default_detail = "Authentication credentials are invalid."


class ConflictError(AppError):
    error_code = ErrorCode.CONFLICT
    status_code = status.HTTP_409_CONFLICT
    default_detail = "The request conflicts with the current state."


class RateLimitedError(AppError):
    error_code = ErrorCode.RATE_LIMITED
    status_code = status.HTTP_429_TOO_MANY_REQUESTS
    default_detail = "Too many requests."


class UpstreamUnavailableError(AppError):
    error_code = ErrorCode.UPSTREAM_UNAVAILABLE
    status_code = status.HTTP_502_BAD_GATEWAY
    default_detail = "An upstream service is unavailable."


class FeatureDisabledError(AppError):
    error_code = ErrorCode.FEATURE_DISABLED
    status_code = status.HTTP_403_FORBIDDEN
    default_detail = "This feature is disabled."


class PaymentRequiredError(AppError):
    error_code = ErrorCode.PAYMENT_REQUIRED
    status_code = status.HTTP_402_PAYMENT_REQUIRED
    default_detail = "Payment is required."


class TierLimitExceeded(AppError):
    error_code = ErrorCode.TIER_LIMIT_EXCEEDED
    status_code = status.HTTP_402_PAYMENT_REQUIRED
    default_detail = "You have reached your plan's tenant limit. Upgrade to add more."


class TierFeatureGated(AppError):
    error_code = ErrorCode.FEATURE_REQUIRES_UPGRADE
    status_code = status.HTTP_402_PAYMENT_REQUIRED
    default_detail = "This feature is not included in your plan. Upgrade to unlock it."


class ServerError(AppError):
    error_code = ErrorCode.SERVER_ERROR
    status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
    default_detail = "An unexpected error occurred."


def _envelope(code: str, message: str, details: Any | None) -> dict[str, Any]:
    error: dict[str, Any] = {"code": code, "message": message}
    if details is not None:
        error["details"] = details
    return {"error": error}


# Map built-in DRF status codes to canonical error codes for non-AppError cases.
_STATUS_TO_CODE: dict[int, ErrorCode] = {
    status.HTTP_400_BAD_REQUEST: ErrorCode.VALIDATION_ERROR,
    status.HTTP_401_UNAUTHORIZED: ErrorCode.AUTH_REQUIRED,
    status.HTTP_403_FORBIDDEN: ErrorCode.PERMISSION_DENIED,
    status.HTTP_404_NOT_FOUND: ErrorCode.NOT_FOUND,
    status.HTTP_405_METHOD_NOT_ALLOWED: ErrorCode.VALIDATION_ERROR,
    status.HTTP_406_NOT_ACCEPTABLE: ErrorCode.VALIDATION_ERROR,
    status.HTTP_409_CONFLICT: ErrorCode.CONFLICT,
    status.HTTP_415_UNSUPPORTED_MEDIA_TYPE: ErrorCode.VALIDATION_ERROR,
    status.HTTP_429_TOO_MANY_REQUESTS: ErrorCode.RATE_LIMITED,
}


def exception_handler(exc: Exception, context: dict[str, Any]) -> Response | None:
    """DRF ``EXCEPTION_HANDLER`` producing the standard error envelope."""
    # Normalize Django-native exceptions DRF would otherwise pass through unhandled.
    if isinstance(exc, Http404):
        exc = NotFoundError()
    elif isinstance(exc, DjangoPermissionDenied):
        exc = PermissionDeniedError()

    if isinstance(exc, AppError):
        return Response(
            _envelope(exc.error_code.value, exc.message, exc.details),
            status=exc.status_code,
        )

    response = drf_exception_handler(exc, context)
    if response is None:
        # Unhandled exception → generic 500 envelope (never leak internals).
        return Response(
            _envelope(ErrorCode.SERVER_ERROR.value, ServerError.default_detail, None),
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

    code = _STATUS_TO_CODE.get(response.status_code, ErrorCode.SERVER_ERROR)
    data = response.data

    if isinstance(exc, DRFValidationError):
        message = ValidationError.default_detail
        details: Any | None = data
    elif isinstance(data, dict) and "detail" in data:
        message = str(data["detail"])
        details = None
    else:
        message = str(data)
        details = data if isinstance(data, (dict, list)) else None

    response.data = _envelope(code.value, message, details)
    return response
