"""Concrete EC verification vendor client — EPIC-17.T-002.

:class:`ECVerificationProvider` is a thin HTTP client over the approved Election
Commission verification vendor. It POSTs the NID + name + DOB, reads a single
match boolean out of the response, and returns a normalized boolean-only
:class:`VerificationOutcome`. The raw vendor payload is **never** returned,
logged, or stored — once the boolean and opaque ``provider_ref`` are extracted,
the response body is discarded.

Credentials and the endpoint come from Django settings. Submitting PII to the
vendor is legally gated on a Data Processing Agreement: the provider refuses to
make any call unless ``EC_VERIFICATION_DPA_REF`` is configured (PDPA
requirement).
"""

from __future__ import annotations

from typing import Any

import requests
from django.conf import settings

from .base import VerificationProvider, VerificationProviderError
from .dto import VerificationOutcome

__all__ = ["ECVerificationProvider"]


class ECVerificationProvider(VerificationProvider):
    """HTTP client for the approved EC verification vendor (boolean-only)."""

    def __init__(
        self,
        *,
        endpoint_url: str | None = None,
        api_key: str | None = None,
        dpa_ref: str | None = None,
        timeout: float | None = None,
        session: requests.Session | None = None,
    ) -> None:
        self._endpoint_url = (
            endpoint_url
            if endpoint_url is not None
            else getattr(settings, "EC_VERIFICATION_ENDPOINT_URL", "")
        )
        self._api_key = (
            api_key
            if api_key is not None
            else getattr(settings, "EC_VERIFICATION_API_KEY", "")
        )
        self._dpa_ref = (
            dpa_ref
            if dpa_ref is not None
            else getattr(settings, "EC_VERIFICATION_DPA_REF", "")
        )
        self._timeout = (
            timeout
            if timeout is not None
            else getattr(settings, "EC_VERIFICATION_TIMEOUT", 30.0)
        )
        self._session = session or requests

    def verify(self, nid: str, name: str, dob: str) -> VerificationOutcome:
        # PDPA gate: never send PII to the vendor without a DPA on file.
        if not self._dpa_ref:
            raise VerificationProviderError(
                "EC_VERIFICATION_DPA_REF is not configured; refusing to submit "
                "PII to the EC vendor without a Data Processing Agreement."
            )
        if not self._endpoint_url:
            raise VerificationProviderError(
                "EC_VERIFICATION_ENDPOINT_URL is not configured."
            )

        payload = {"nid": nid, "name": name, "dob": dob, "dpa_ref": self._dpa_ref}
        headers = {"Content-Type": "application/json", "Accept": "application/json"}
        if self._api_key:
            headers["Authorization"] = f"Bearer {self._api_key}"

        try:
            response = self._session.post(
                self._endpoint_url,
                json=payload,
                headers=headers,
                timeout=self._timeout,
            )
        except requests.RequestException as exc:
            # Transport failure — normalize to error, never raise to caller.
            return VerificationOutcome.error_result(f"transport error: {exc}")

        if not response.ok:
            return VerificationOutcome.error_result(
                f"vendor returned HTTP {response.status_code}"
            )

        try:
            body: Any = response.json()
        except ValueError:
            return VerificationOutcome.error_result("vendor returned non-JSON response")

        if not isinstance(body, dict):
            return VerificationOutcome.error_result("vendor returned unexpected shape")

        # Extract ONLY the boolean + opaque ref, then drop the rest of `body`.
        return self._normalize(body)

    @staticmethod
    def _normalize(body: dict[str, Any]) -> VerificationOutcome:
        """Reduce a vendor response to a boolean-only outcome + opaque ref.

        Reads ``matched`` (bool) and ``transaction_id`` (opaque ref). Any raw EC
        fields present in ``body`` are intentionally ignored and never copied
        onto the returned DTO.
        """
        provider_ref = str(body.get("transaction_id") or "")
        matched = body.get("matched")
        if matched is True:
            return VerificationOutcome.matched_result(provider_ref=provider_ref)
        if matched is False:
            return VerificationOutcome.not_matched_result(provider_ref=provider_ref)
        return VerificationOutcome.error_result(
            "vendor response missing match boolean", provider_ref=provider_ref
        )
