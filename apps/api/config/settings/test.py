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

# Run Celery tasks synchronously, in-process — no live broker needed in tests.
CELERY_TASK_ALWAYS_EAGER = True
CELERY_TASK_EAGER_PROPAGATES = True

# Deterministic Fernet key so encryption round-trips in tests without env setup.
FIELD_ENCRYPTION_KEY = "32SDpIJPPLw0lyx6ULQ8-e31Vqhl6zy77JSD8LKIBHI="

# Deterministic JWT signing key (>=32 bytes) so simplejwt does not warn about a
# short HMAC key during the suite; prod supplies a real JWT_SIGNING_KEY via env.
SIMPLE_JWT = {**SIMPLE_JWT, "SIGNING_KEY": "test-jwt-signing-key-at-least-32-bytes-long"}  # noqa: F405

# Force filesystem (encrypted) object storage in tests regardless of a local
# ``.env`` setting S3_BUCKET — the suite must never reach a real S3 bucket.
# store_encrypted() falls back to ENCRYPTED_STORAGE_ROOT when S3_BUCKET is empty.
S3_BUCKET = ""
