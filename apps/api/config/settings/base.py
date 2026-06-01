"""Shared Django settings for the Khatir API.

Environment-specific modules (dev/prod/test) import from here and override
only what they need. All configuration is read from the environment via
``django-environ`` — never scatter ``os.environ`` access through the code.
"""

from pathlib import Path

import environ

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
    "django_celery_beat",
]

LOCAL_APPS = [
    "khatir.core",
    "khatir.health",
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

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
}
