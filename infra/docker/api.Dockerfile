# Khatir Django API image — uv-managed, multi-stage-style single image.
#
# Build context is the repo root (see docker-compose.yml). The application
# lives in apps/api/. Uses the official uv image to resolve and install the
# locked dependency set, then runs under a non-root user via gunicorn.

FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT=/usr/local \
    DJANGO_ENV=prod

WORKDIR /app

# Install dependencies first (cached layer) from the lockfile + manifest only.
COPY apps/api/pyproject.toml apps/api/uv.lock ./
RUN uv sync --frozen --no-install-project --no-dev

# Copy the application source, then register the project itself.
COPY apps/api/ ./
RUN uv sync --frozen --no-dev

# Run as an unprivileged user.
RUN useradd --create-home --uid 10001 appuser && chown -R appuser /app
USER appuser

EXPOSE 8000

# Gunicorn serves the WSGI app; the settings module is derived from DJANGO_ENV
# at runtime via config/wsgi.py.
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3"]
