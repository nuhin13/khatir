# Khatir AI gateway image — uv-managed FastAPI service (EPIC-14).
#
# Build context is this directory (services/ai-gateway/; see docker-compose.yml).
# Resolves the locked dependency set with the official uv image, then serves the
# ASGI app under uvicorn as a non-root user.

FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT=/usr/local

WORKDIR /app

# Install dependencies first (cached layer) from the manifest + lockfile only.
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-install-project --no-dev

# Copy the application source.
COPY . ./

# Run as an unprivileged user.
RUN useradd --create-home --uid 10001 appuser && chown -R appuser /app
USER appuser

EXPOSE 8100

# uvicorn serves the ASGI app exposed as `app` in main.py.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8100"]
