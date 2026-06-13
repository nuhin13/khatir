"""Local development settings."""

from .base import *  # noqa: F401, F403
from .base import env

DEBUG = env.bool("DJANGO_DEBUG", default=True)

ALLOWED_HOSTS = env.list(
    "DJANGO_ALLOWED_HOSTS", default=["localhost", "127.0.0.1", "0.0.0.0", "10.0.2.2"]
)

CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:3001",
    "http://localhost:3002",
    "http://localhost:3003",
]
CORS_ALLOW_CREDENTIALS = True
