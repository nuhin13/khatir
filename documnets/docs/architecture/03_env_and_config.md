# 03 · Environment & Configuration

> How config flows, where secrets live, env var naming, and the rule that business values are DB config not env.

---

## 1. Three layers of configuration

Config comes from three places, in increasing order of runtime-changeability:

| Layer | What lives here | Changeable by | Example |
|-------|-----------------|---------------|---------|
| **1. Env vars** | Secrets, infra endpoints, deploy-time toggles | DevOps (redeploy) | `DATABASE_URL`, `JWT_SIGNING_KEY`, `S3_BUCKET` |
| **2. Code defaults** | Sensible fallbacks, structural constants | Developers (code change) | pagination page size, JWT lifetime |
| **3. DB config (admin portal)** | Business values | Admin staff (live, no deploy) | pricing tiers, free-tenant limit, reminder cadence, AI provider, feature flags |

**The rule:** if a non-engineer might want to change it, it belongs in Layer 3 (DB), surfaced in the admin portal. If it's a secret or an infra address, Layer 1 (env). Everything else, Layer 2.

**Never** put pricing, limits, cadences, or provider choices in env vars or code constants. They are `SystemConfig` / `PricingTier` / `FeatureFlag` / `AIProvider` rows.

---

## 2. Env var conventions

- **UPPER_SNAKE_CASE.**
- Prefix by domain where useful: `DB_`, `REDIS_`, `JWT_`, `S3_`, `WHATSAPP_`, `SMS_`, `AI_`, `SENTRY_`.
- Booleans are `true`/`false` strings, parsed via decouple's `cast=bool`.
- No secrets in the repo. `.env` is gitignored. `.env.example` lists every key with a dummy/empty value and a comment.
- Backend reads env via `python-decouple` in `config/settings/`. Never `os.environ` scattered in code.
- Flutter reads build-time config via `--dart-define` (see §5). Never bake secrets into the Flutter binary.
- Next.js: public vars prefixed `NEXT_PUBLIC_`; everything else server-only.

### `.env.example` (canonical key list — EPIC-00 T-005 creates this)
```bash
# ── Core ──────────────────────────────────────────────
DJANGO_ENV=dev                      # dev | prod | test
DJANGO_SECRET_KEY=                  # generate per environment
DJANGO_DEBUG=true
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
API_BASE_URL=http://localhost:8000

# ── Database ──────────────────────────────────────────
DB_NAME=khatir
DB_USER=khatir
DB_PASSWORD=khatir
DB_HOST=localhost
DB_PORT=5432

# ── Redis ─────────────────────────────────────────────
REDIS_URL=redis://localhost:6379/0
CELERY_BROKER_URL=redis://localhost:6379/1
CELERY_RESULT_BACKEND=redis://localhost:6379/2

# ── Auth / JWT ────────────────────────────────────────
JWT_SIGNING_KEY=                    # separate from DJANGO_SECRET_KEY
JWT_ACCESS_LIFETIME_MIN=30
JWT_REFRESH_LIFETIME_DAYS=30
OTP_TTL_SECONDS=300
OTP_LENGTH=6

# ── Object storage (S3-compatible) ────────────────────
S3_ENDPOINT_URL=
S3_ACCESS_KEY=
S3_SECRET_KEY=
S3_BUCKET=khatir-media
S3_REGION=

# ── Field encryption ──────────────────────────────────
FIELD_ENCRYPTION_KEY=               # Fernet key for NID/personal data

# ── Messaging (filled in EPIC-07/15) ──────────────────
WHATSAPP_API_URL=
WHATSAPP_API_TOKEN=
WHATSAPP_PHONE_ID=
SMS_GATEWAY_URL=
SMS_GATEWAY_KEY=

# ── AI Gateway (EPIC-14) ──────────────────────────────
AI_GATEWAY_URL=http://localhost:8100
AI_GATEWAY_INTERNAL_TOKEN=

# ── Observability ─────────────────────────────────────
SENTRY_DSN=
LOG_LEVEL=INFO

# ── Admin portal ──────────────────────────────────────
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000
ADMIN_SESSION_SECRET=
```

---

## 3. Secrets management

- **Local dev:** plain `.env` file (gitignored). `make up` loads it.
- **CI:** GitHub Actions secrets.
- **Production:** environment injected by the host/orchestrator (never a committed file). For BD hosting, use the provider's secret store or an injected `.env` placed by deploy script (mode 600).
- **Rotation:** `JWT_SIGNING_KEY`, `FIELD_ENCRYPTION_KEY`, and provider tokens are rotatable. `FIELD_ENCRYPTION_KEY` rotation requires a re-encryption migration — document it when it happens.
- **API keys for AI providers** are NOT env vars. They live encrypted in the `AIProvider` table, managed via admin portal. Only the AI gateway's own internal token is env.

---

## 4. DB config (Layer 3) — the SystemConfig pattern

Admin-tunable values live in a `SystemConfig` key-value table (typed) plus dedicated tables for richer config (`PricingTier`, `FeatureFlag`, `AIProvider`, `NotificationTemplate`).

`SystemConfig` seed keys (created across epics, listed canonically in admin spec §4.8):
```
free_tier_tenant_limit        int    2
rent_reminder_1_hours         int    24
rent_reminder_2_hours         int    48
verification_fee_bdt          money  75
visitor_log_retention_days    int    90
dmp_form_template_version     text   v2.1
lease_template_version        text   v1.0
referral_reward_months        int    1
support_whatsapp_number       text   +880...
intro_slide_skip_allowed      bool   true
```

**Access pattern:** never read these directly in many places. Wrap in a cached accessor:
```python
# khatir/core/config.py
def get_config(key: str):
    # cached read with 60s TTL; invalidated on admin write
    ...
```

**Clients** fetch a public subset via `GET /api/v1/config/public` (e.g. `intro_slide_skip_allowed`, `support_whatsapp_number`) and re-fetch on app launch, so a Layer-3 change is live within one app session / 60s.

---

## 5. Flutter build config

No secrets in the app. Only the API base URL and environment flavor, passed at build:
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=APP_ENV=dev
flutter build apk --dart-define=API_BASE_URL=https://api.khatir.com.bd --dart-define=APP_ENV=prod
```
Read in Dart:
```dart
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');
const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
```
Flavors: `dev`, `staging`, `prod` (Android flavors + iOS schemes — set up in EPIC-00 T-004).

---

## 6. Settings module split (Django)

```
config/settings/
├── base.py     Everything shared. Reads env via decouple.
├── dev.py      from base import *; DEBUG=True; console email; relaxed CORS
├── prod.py     from base import *; DEBUG=False; strict security headers; real services
└── test.py     from base import *; fast hashers; in-memory/locmem; eager celery
```
Selected via `DJANGO_SETTINGS_MODULE=config.settings.dev` (set by env `DJANGO_ENV` mapping in `manage.py`/`wsgi.py`).

---

## 7. Rules for agents

1. New secret or infra endpoint → add to `.env.example` with comment, read via decouple, never hardcode.
2. New business value → `SystemConfig` row (or dedicated table) + admin portal surface, never env/constant.
3. Never log secrets or full NID numbers. Mask.
4. Never commit a real `.env`.
5. Client-needed config goes through `GET /api/v1/config/public`, not bundled into the build.
