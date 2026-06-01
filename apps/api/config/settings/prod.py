"""Production settings.

Secrets and infra endpoints come from the environment (injected by the host),
never from a committed file. ``DJANGO_SECRET_KEY`` and ``DJANGO_ALLOWED_HOSTS``
are required at boot.
"""

from khatir.core.observability import init_sentry

from .base import *  # noqa: F401, F403
from .base import DJANGO_ENV, SENTRY_DSN, env

DEBUG = False

# ── Observability (T-015) ─────────────────────────────────────────────
# Report unhandled exceptions to Sentry with an environment tag. No-op when
# SENTRY_DSN is unset, so the app still boots without an account configured.
init_sentry(dsn=SENTRY_DSN, environment=DJANGO_ENV)

# Required in production — env() raises if unset.
SECRET_KEY = env("DJANGO_SECRET_KEY")
ALLOWED_HOSTS = env.list("DJANGO_ALLOWED_HOSTS")

# ── Security hardening ────────────────────────────────────────────────
SECURE_SSL_REDIRECT = env.bool("DJANGO_SECURE_SSL_REDIRECT", default=True)
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = env.int("DJANGO_SECURE_HSTS_SECONDS", default=31536000)
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
