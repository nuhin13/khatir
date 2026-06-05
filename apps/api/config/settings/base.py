"""Shared Django settings for the Khatir API.

Environment-specific modules (dev/prod/test) import from here and override
only what they need. All configuration is read from the environment via
``django-environ`` — never scatter ``os.environ`` access through the code.
"""

from pathlib import Path

import environ
from celery.schedules import crontab

# apps/api/ — manage.py lives here; config/ is a package under it.
BASE_DIR = Path(__file__).resolve().parent.parent.parent

env = environ.Env(
    DJANGO_DEBUG=(bool, False),
    DJANGO_ALLOWED_HOSTS=(list, ["localhost", "127.0.0.1"]),
)

# Load a .env file from the repo root if present (local dev convenience).
_env_file = BASE_DIR.parent.parent / ".env"
if _env_file.exists():
    environ.Env.read_env(str(_env_file))

# ── Core ──────────────────────────────────────────────────────────────
SECRET_KEY = env("DJANGO_SECRET_KEY", default="insecure-dev-key-change-me")
DEBUG = env.bool("DJANGO_DEBUG", default=False)
ALLOWED_HOSTS = env.list("DJANGO_ALLOWED_HOSTS", default=["localhost", "127.0.0.1"])

# ── Applications ──────────────────────────────────────────────────────
DJANGO_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
]

THIRD_PARTY_APPS = [
    "rest_framework",
    "rest_framework_simplejwt",
    "rest_framework_simplejwt.token_blacklist",
    "django_celery_beat",
    "drf_spectacular",
]

LOCAL_APPS = [
    "khatir.core",
    "khatir.accounts",
    "khatir.properties",
    "khatir.tenants",
    "khatir.leases",
    "khatir.rent",
    "khatir.maintenance",
    "khatir.billing",
    "khatir.admin_portal",
    "khatir.dmpforms",
    "khatir.featureflags",
    "khatir.ai_providers",
    "khatir.notifications",
    "khatir.compliance",
    "khatir.dashboard",
    "khatir.health",
    "khatir.govexport",
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

# ── Authentication ────────────────────────────────────────────────────
# Custom phone-based user (T-002). Set before the first domain migration so
# every ForeignKey(settings.AUTH_USER_MODEL) resolves to it.
AUTH_USER_MODEL = "accounts.User"

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

# ── Database (PostgreSQL via psycopg3) ────────────────────────────────
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": env("DB_NAME", default="khatir"),
        "USER": env("DB_USER", default="khatir"),
        "PASSWORD": env("DB_PASSWORD", default="khatir"),
        "HOST": env("DB_HOST", default="localhost"),
        "PORT": env("DB_PORT", default="5432"),
    }
}

# ── Cache (Redis) ─────────────────────────────────────────────────────
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.redis.RedisCache",
        "LOCATION": env("REDIS_URL", default="redis://localhost:6379/0"),
    }
}

# ── Celery ────────────────────────────────────────────────────────────
# Broker + result backend are Redis, on dedicated DBs (see .env.example:
# /0 cache, /1 broker, /2 result). All keys are CELERY_-namespaced so the
# Celery app can load them via config_from_object(..., namespace="CELERY").
CELERY_BROKER_URL = env("CELERY_BROKER_URL", default="redis://localhost:6379/1")
CELERY_RESULT_BACKEND = env("CELERY_RESULT_BACKEND", default="redis://localhost:6379/2")
CELERY_TASK_SERIALIZER = "json"
CELERY_RESULT_SERIALIZER = "json"
CELERY_ACCEPT_CONTENT = ["json"]
CELERY_TIMEZONE = "UTC"  # keep in sync with TIME_ZONE below
CELERY_TASK_ALWAYS_EAGER = env.bool("CELERY_TASK_ALWAYS_EAGER", default=False)
# DB-backed schedule for Celery Beat; later epics register periodic tasks here.
CELERY_BEAT_SCHEDULER = "django_celery_beat.schedulers:DatabaseScheduler"
# Static Beat entries. The DatabaseScheduler still honours CELERY_BEAT_SCHEDULE,
# syncing these definitions into its DB table on startup.
CELERY_BEAT_SCHEDULE = {
    # Daily roll-forward + overdue flagging for active leases (EPIC-06.T-005).
    # Runs every day at 02:00 UTC: idempotent schedule generation to the rolling
    # horizon plus marking unpaid rent past its grace window as overdue.
    "leases-roll-schedules-and-flag-overdue": {
        "task": "khatir.leases.tasks.roll_schedules_and_flag_overdue",
        "schedule": crontab(hour=2, minute=0),
    },
    # Rent reminders (EPIC-07.T-008) run hourly; the task reads the cadence
    # thresholds + max from SystemConfig, so this only sets the wake-up rate.
    "send-rent-reminders": {
        "task": "khatir.rent.tasks.send_rent_reminders",
        "schedule": 3600.0,  # every hour
    },
}

# Public base URL the tenant-facing rent link (/r/{token}) is built from (T-004).
PUBLIC_WEB_BASE_URL = env("PUBLIC_WEB_BASE_URL", default="https://khatir.app")

# ── Password validation ───────────────────────────────────────────────
AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

# ── Internationalization ──────────────────────────────────────────────
LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

# ── Static files ──────────────────────────────────────────────────────
STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# ── Field encryption ──────────────────────────────────────────────────
# Fernet key for personal/sensitive fields (NID, etc.). See core/encryption.py.
FIELD_ENCRYPTION_KEY = env("FIELD_ENCRYPTION_KEY", default="")

# ── Encrypted object storage (EPIC-04 T-003 / core/storage.py) ─────────
# Sensitive files (NID images, payment proofs, generated DMP PDFs) live in
# S3-compatible storage in prod, encrypted at rest (SSE) and never
# public-readable; retrieval is via short-lived signed URLs. When no S3 bucket
# is configured (dev/test), a local filesystem root under a non-public path
# keeps the pipeline runnable. Never serve either backend publicly.
S3_ENDPOINT_URL = env("S3_ENDPOINT_URL", default="")
S3_ACCESS_KEY = env("S3_ACCESS_KEY", default="")
S3_SECRET_KEY = env("S3_SECRET_KEY", default="")
S3_BUCKET = env("S3_BUCKET", default="")
S3_REGION = env("S3_REGION", default="")
# Server-side encryption header for stored objects (AES256 or aws:kms).
S3_SSE = env("S3_SSE", default="AES256")
ENCRYPTED_STORAGE_ROOT = env("ENCRYPTED_STORAGE_ROOT", default=str(BASE_DIR / "private_media"))
ENCRYPTED_STORAGE_PUBLIC_BASE = env(
    "ENCRYPTED_STORAGE_PUBLIC_BASE", default="https://storage.local"
)

# ── Messaging / notification channels (T-004) ─────────────────────────
# Credentials for the WhatsApp Business API and the SMS gateway. All default to
# empty so the app boots without them; in dev the console sender is used and
# never touches these. When unset in prod, the WhatsApp/SMS senders raise a
# clear configuration error rather than failing silently (T-004 §2).
WHATSAPP_API_URL = env("WHATSAPP_API_URL", default="")
WHATSAPP_API_TOKEN = env("WHATSAPP_API_TOKEN", default="")
WHATSAPP_PHONE_ID = env("WHATSAPP_PHONE_ID", default="")
SMS_GATEWAY_URL = env("SMS_GATEWAY_URL", default="")
SMS_GATEWAY_KEY = env("SMS_GATEWAY_KEY", default="")

# ── AI gateway (EPIC-14) ──────────────────────────────────────────────
# Base URL of the FastAPI ai-gateway microservice and the shared internal
# token Django presents on every call (see services/ai-gateway, EPIC-14.T-002).
# Both default to empty so the app boots without the gateway running; the
# Django-side client (khatir.ai_providers.client) raises a clear configuration
# error when AI_GATEWAY_URL is unset rather than failing silently.
AI_GATEWAY_URL = env("AI_GATEWAY_URL", default="")
AI_GATEWAY_INTERNAL_TOKEN = env("AI_GATEWAY_INTERNAL_TOKEN", default="")
AI_GATEWAY_TIMEOUT = env.float("AI_GATEWAY_TIMEOUT", default=30.0)

# ── Observability (T-015) ─────────────────────────────────────────────
# Structured logging: JSON in prod (DEBUG=False), human-readable in dev. A
# PII-masking filter (core/logging.py) strips NID/OTP/token/secret/trx values
# from every record. Sentry init lives in prod.py and is a no-op without a DSN.
LOG_LEVEL = env("LOG_LEVEL", default="INFO")
SENTRY_DSN = env("SENTRY_DSN", default="")
# Environment tag attached to Sentry events: dev | staging | prod.
DJANGO_ENV = env("DJANGO_ENV", default="dev")

from khatir.core.logging import build_logging_config  # noqa: E402

LOGGING = build_logging_config(log_level=LOG_LEVEL, json_logs=not DEBUG)

# ── Django REST Framework ─────────────────────────────────────────────
# Custom exception handler (T-005) produces the standard error envelope; the
# core pagination class produces the {results, pagination} envelope.
REST_FRAMEWORK = {
    "EXCEPTION_HANDLER": "khatir.core.exceptions.exception_handler",
    "DEFAULT_PAGINATION_CLASS": "khatir.core.pagination.StandardPageNumberPagination",
    "PAGE_SIZE": 20,
    # OpenAPI 3 schema generation (drf-spectacular) powering Swagger UI + ReDoc.
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    # Scoped throttle rates for the OTP auth endpoints (T-007). Caps abuse on
    # request-otp (SMS/WhatsApp cost bombs) and verify-otp (code brute force),
    # keyed by phone and by IP. Tunable per environment without code changes;
    # state lives in the cache backend (Redis in prod). Defaults follow T-007
    # §15. The per-phone resend cooldown (T-003) still applies on top of these.
    "DEFAULT_THROTTLE_RATES": {
        "request_otp_phone": env("THROTTLE_REQUEST_OTP_PHONE", default="5/hour"),
        "request_otp_ip": env("THROTTLE_REQUEST_OTP_IP", default="20/hour"),
        "verify_otp_phone": env("THROTTLE_VERIFY_OTP_PHONE", default="10/10min"),
        "verify_otp_ip": env("THROTTLE_VERIFY_OTP_IP", default="30/10min"),
        # Per-user cap on the OCR endpoint (EPIC-04.T-005): each call hits a paid
        # external OCR provider, so cap volume per landlord/manager. Tunable per
        # environment without code changes.
        "tenant_ocr": env("THROTTLE_TENANT_OCR", default="30/hour"),
        # Per-user cap on the voice endpoint (EPIC-04.T-006): each call hits a
        # paid external ASR provider, same cost profile as OCR. Tunable per env.
        "tenant_voice": env("THROTTLE_TENANT_VOICE", default="30/hour"),
        # Admin-portal auth (EPIC-11.T-003): cap password + MFA brute force on
        # the staff login surface, keyed by submitted email and by client IP.
        "admin_login_email": env("THROTTLE_ADMIN_LOGIN_EMAIL", default="10/10min"),
        "admin_login_ip": env("THROTTLE_ADMIN_LOGIN_IP", default="30/10min"),
        # verify-mfa carries an opaque mfa_token (no email), so it is capped by
        # IP only — the per-email login throttle already gates how many MFA
        # challenges a given account can trigger upstream.
        "admin_mfa_ip": env("THROTTLE_ADMIN_MFA_IP", default="30/10min"),
    },
}

# ── OpenAPI / Swagger (drf-spectacular) ───────────────────────────────
SPECTACULAR_SETTINGS = {
    "TITLE": "Khatir API",
    "DESCRIPTION": "Landlord-first compliance SaaS for Dhaka — backend API.",
    "VERSION": "0.1.0",
    "SERVE_INCLUDE_SCHEMA": False,
}

# ── JWT (djangorestframework-simplejwt, T-006) ────────────────────────
# Layer-1 secret (signing key) is env-only and separate from DJANGO_SECRET_KEY
# (03_env_and_config.md §5). Lifetimes are Layer-2 code defaults overridable by
# env: short access, long refresh. Refresh rotation + blacklist-on-logout are
# on so a logged-out refresh token can no longer mint access tokens.
from datetime import timedelta  # noqa: E402

# An empty JWT_SIGNING_KEY in the env file would override the default with "",
# leaving simplejwt unable to sign ("HMAC key must not be empty"). Treat blank
# as unset and fall back to SECRET_KEY.
JWT_SIGNING_KEY = env("JWT_SIGNING_KEY", default="").strip() or SECRET_KEY
JWT_ACCESS_LIFETIME_MIN = env.int("JWT_ACCESS_LIFETIME_MIN", default=30)
JWT_REFRESH_LIFETIME_DAYS = env.int("JWT_REFRESH_LIFETIME_DAYS", default=30)

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=JWT_ACCESS_LIFETIME_MIN),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=JWT_REFRESH_LIFETIME_DAYS),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "SIGNING_KEY": JWT_SIGNING_KEY,
    "ALGORITHM": "HS256",
    "AUTH_HEADER_TYPES": ("Bearer",),
    "USER_ID_FIELD": "id",
    "USER_ID_CLAIM": "user_id",
}

# ── Admin-portal auth (EPIC-11.T-003) ─────────────────────────────────
# Staff (admin_portal.AdminUser) auth is *completely separate* from the
# customer JWT above: a dedicated signing key (env-only), self-contained
# HS256 tokens (PyJWT, not simplejwt — AdminUser is not a Django auth user),
# a short access TTL, and a mandatory TOTP MFA step. A blank env value is
# treated as unset and falls back to a derived per-deployment key so the two
# realms can never share a signing secret by accident.
ADMIN_JWT_SIGNING_KEY = (
    env("ADMIN_JWT_SIGNING_KEY", default="").strip() or f"admin::{SECRET_KEY}"
)
# Short access lifetime (task §15: e.g. 60 min). The admin session timeout is a
# separate, ops-tunable cap surfaced to the UI; the token never outlives it.
ADMIN_JWT_ACCESS_LIFETIME_MIN = env.int("ADMIN_JWT_ACCESS_LIFETIME_MIN", default=60)
ADMIN_SESSION_TIMEOUT_MINUTES = env.int("ADMIN_SESSION_TIMEOUT_MINUTES", default=60)
# Short-lived token that carries the user past the password step to the TOTP
# step; it is useless for anything else and expires quickly.
ADMIN_MFA_CHALLENGE_LIFETIME_MIN = env.int("ADMIN_MFA_CHALLENGE_LIFETIME_MIN", default=5)
# When true, an account with a configured TOTP secret must complete MFA; login
# returns an ``mfa_required`` challenge instead of a token. Accounts without a
# TOTP secret can still log in directly (first-run / pre-MFA-setup).
ADMIN_MFA_REQUIRED = env.bool("ADMIN_MFA_REQUIRED", default=True)

# ── PDPA data-request SLA (EPIC-16.T-004) ─────────────────────────────
# A data subject's export/erasure request must be fulfilled within this many
# days of submission (regulatory deadline). Used to compute ``sla_due`` when a
# request is created and to classify queue rows as on_track / due_soon / overdue.
DATA_REQUEST_SLA_DAYS = env.int("DATA_REQUEST_SLA_DAYS", default=30)
# A request whose deadline is within this many days is flagged ``due_soon``.
DATA_REQUEST_SLA_DUE_SOON_DAYS = env.int("DATA_REQUEST_SLA_DUE_SOON_DAYS", default=7)
