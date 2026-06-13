"""Tests for the exception handler / error envelope."""

import pytest
from rest_framework import status
from rest_framework.exceptions import NotAuthenticated
from rest_framework.exceptions import ValidationError as DRFValidationError
from rest_framework.response import Response
from rest_framework.test import APIClient

from khatir.core.exceptions import (
    ConflictError,
    NotFoundError,
    ValidationError,
    exception_handler,
)


def _handle(exc: Exception) -> Response:
    response = exception_handler(exc, {})
    assert response is not None
    return response


def test_app_error_envelope_shape() -> None:
    resp = _handle(ValidationError("Bad input", details={"email": ["required"]}))
    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.data == {
        "error": {
            "code": "validation_error",
            "message": "Bad input",
            "details": {"email": ["required"]},
        }
    }


def test_app_error_without_details_omits_key() -> None:
    resp = _handle(NotFoundError("Nope"))
    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert resp.data == {"error": {"code": "not_found", "message": "Nope"}}


def test_conflict_code() -> None:
    resp = _handle(ConflictError())
    assert resp.data["error"]["code"] == "conflict"
    assert resp.status_code == status.HTTP_409_CONFLICT


def test_drf_validation_error_mapped() -> None:
    resp = _handle(DRFValidationError({"name": ["This field is required."]}))
    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.data["error"]["code"] == "validation_error"
    assert resp.data["error"]["details"] == {"name": ["This field is required."]}


def test_drf_not_authenticated_mapped() -> None:
    resp = _handle(NotAuthenticated())
    assert resp.data["error"]["code"] == "auth_required"
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED


def test_unhandled_exception_is_generic_500() -> None:
    resp = _handle(RuntimeError("boom"))
    assert resp.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    assert resp.data["error"]["code"] == "server_error"
    # Internal detail must not leak.
    assert "boom" not in resp.data["error"]["message"]


@pytest.mark.django_db
def test_envelope_over_http(api_client: APIClient) -> None:
    # POST to a GET-only DRF view raises MethodNotAllowed → handler builds envelope.
    resp = api_client.post("/api/v1/config/public", {})
    assert resp.status_code == status.HTTP_405_METHOD_NOT_ALLOWED
    body = resp.json()
    assert set(body["error"]) >= {"code", "message"}
    assert body["error"]["code"] == "validation_error"
