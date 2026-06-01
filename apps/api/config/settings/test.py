"""Test settings.

Uses an in-memory SQLite database and a local-memory cache so the suite runs
without external services (Postgres/Redis). The production path still targets
Postgres (psycopg3) + Redis via ``base``/``prod``; this override only affects
the test runner. See T-004 self-review for the rationale.
"""

from .base import *  # noqa: F401, F403

DEBUG = False

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": ":memory:",
    }
}

CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
    }
}

PASSWORD_HASHERS = ["django.contrib.auth.hashers.MD5PasswordHasher"]
