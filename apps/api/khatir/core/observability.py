"""Sentry initialisation for the Django backend.

``init_sentry`` is a guarded no-op when ``SENTRY_DSN`` is unset, so the app
boots and runs without an account configured (``T-015`` §3, §13). When a DSN is
present, unhandled exceptions are reported with an environment tag and a modest
traces sample rate to keep cost down (§15).
"""

from __future__ import annotations


def init_sentry(*, dsn: str, environment: str, traces_sample_rate: float = 0.1) -> bool:
    """Initialise Sentry if ``dsn`` is set. Returns ``True`` when initialised.

    No-op (returns ``False``) when ``dsn`` is empty so a missing DSN never
    crashes startup.
    """
    if not dsn:
        return False

    import sentry_sdk
    from sentry_sdk.integrations.django import DjangoIntegration

    sentry_sdk.init(
        dsn=dsn,
        environment=environment,
        integrations=[DjangoIntegration()],
        traces_sample_rate=traces_sample_rate,
        # Do not attach request bodies / PII — masking is handled at the log
        # layer and we never want NID/OTP/token payloads in Sentry events.
        send_default_pii=False,
    )
    return True
