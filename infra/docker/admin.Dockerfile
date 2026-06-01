# Khatir Next.js admin portal image — multi-stage, standalone output.
#
# Build context is the repo root (see docker-compose.yml). The app lives in
# apps/admin/ and consumes the shared packages/design-tokens workspace package,
# so both paths are copied into the build.

# ── deps ──────────────────────────────────────────────────────────────
FROM node:22-bookworm-slim AS deps
WORKDIR /app
COPY apps/admin/package.json apps/admin/package-lock.json ./apps/admin/
COPY packages/design-tokens/ ./packages/design-tokens/
WORKDIR /app/apps/admin
RUN npm ci

# ── build ─────────────────────────────────────────────────────────────
FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY packages/design-tokens/ ./packages/design-tokens/
COPY apps/admin/ ./apps/admin/
COPY --from=deps /app/apps/admin/node_modules ./apps/admin/node_modules
WORKDIR /app/apps/admin
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# ── runtime ───────────────────────────────────────────────────────────
FROM node:22-bookworm-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=3000

# Next.js standalone output bundles only what the server needs.
COPY --from=build /app/apps/admin/.next/standalone ./
COPY --from=build /app/apps/admin/.next/static ./apps/admin/.next/static
COPY --from=build /app/apps/admin/public ./apps/admin/public

RUN useradd --create-home --uid 10001 appuser && chown -R appuser /app
USER appuser

EXPOSE 3000

CMD ["node", "apps/admin/server.js"]
