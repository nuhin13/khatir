# 02 · Project Structure

> The complete mono-repo layout. When a task says "add file at X," X follows this map. Agents must not invent new top-level folders.

---

## 1. Top level

```
khatir/
├── README.md                  Project intro + how to run (from EPIC-00)
├── Makefile                   All dev commands (make up, test, lint, status, next…)
├── docker-compose.yml         Local dev orchestration
├── .env.example               Template for all env vars (never commit real .env)
├── .gitignore
├── .pre-commit-config.yaml    Lint/format hooks across all apps
│
├── apps/
│   ├── api/                   Django + DRF backend (the monolith)
│   ├── mobile/                Flutter app (landlord/manager/tenant)
│   └── admin/                 Next.js admin portal
│
├── services/                  Microservices (empty until EPIC-14)
│   └── ai-gateway/            FastAPI AI provider abstraction (EPIC-14)
│
├── infra/                     Deployment, CI scripts, ops tooling
│   ├── docker/                Dockerfiles per app
│   ├── scripts/               make-status, make-next, epic-report parsers
│   ├── ci/                    GitHub Actions workflow sources (if extracted)
│   └── deploy/                Production compose / k8s (later)
│
├── packages/                  Shared cross-app code (use sparingly)
│   └── design-tokens/         Notun Din palette as JSON → consumed by all 3 apps
│
└── docs/
    ├── architecture/          These standards docs (00–06 + enums.md)
    ├── product/               BRD, SRS, Backlog, Admin spec (your existing docs)
    ├── logos/                 Brand assets (your existing pack)
    └── epics/                 The work plan (epics + tasks + trackers)
```

---

## 2. `apps/api/` — Django backend

**Folder-by-app (Django apps = bounded contexts).** Each domain is a Django app under `khatir/`.

```
apps/api/
├── manage.py
├── pyproject.toml             ruff + mypy + pytest config
├── requirements/
│   ├── base.txt
│   ├── dev.txt
│   └── prod.txt
├── conftest.py                pytest root fixtures
│
├── config/                    Django project (settings, urls, wsgi/asgi)
│   ├── __init__.py
│   ├── settings/
│   │   ├── base.py            Shared settings
│   │   ├── dev.py             Local dev
│   │   ├── prod.py            Production
│   │   └── test.py            Test runner
│   ├── urls.py                Root URL conf → includes app urls under /api/v1/
│   ├── celery.py              Celery app
│   ├── asgi.py
│   └── wsgi.py
│
├── khatir/                    All domain apps live here
│   ├── core/                  Shared base classes, mixins, utils
│   │   ├── models.py          TimeStampedModel, SoftDeleteModel
│   │   ├── permissions.py     Base permission classes
│   │   ├── pagination.py      Standard pagination
│   │   ├── exceptions.py      Custom exceptions + handler
│   │   ├── responses.py       Standard response envelope helpers
│   │   ├── enums.py           Cross-app enums (Role, Channel, etc.)
│   │   ├── encryption.py      Field encryption helpers
│   │   └── audit.py           AuditEntry writer
│   │
│   ├── accounts/              User, auth, OTP, JWT  (EPIC-01, 02)
│   ├── properties/            Building, Unit  (EPIC-03)
│   ├── tenants/               Tenant, family, NID OCR  (EPIC-04)
│   ├── dmpforms/              DMP form generation  (EPIC-05)
│   ├── leases/                Lease, RentSchedule  (EPIC-06)
│   ├── rent/                  RentRequest, PaymentProof, Payment  (EPIC-07)
│   ├── expenses/              MaintenanceRequest, Expense  (EPIC-08)
│   ├── dashboard/             Aggregations, charts data  (EPIC-09)
│   ├── pricing/               PricingTier, Subscription  (EPIC-10)
│   ├── notifications/         Notification, delivery, templates  (EPIC-15)
│   ├── featureflags/          FeatureFlag, kill-switches  (EPIC-13)
│   ├── aiproxy/               Client to ai-gateway service  (EPIC-14)
│   ├── adminportal/           Admin-only endpoints, AdminUser  (EPIC-11,12,16)
│   ├── verification/          EC NID verify  (EPIC-17, P1)
│   ├── warnings/              Private warnings  (EPIC-20, P1)
│   ├── reviews/               Mutual reviews  (EPIC-21, P1)
│   ├── history/               History flags  (EPIC-24, P2)
│   └── gatekeeper/            Caretaker, visitor log  (EPIC-25, P2)
│
└── templates/
    └── tenant_web/            Tenant web-link pages (rent proof, receipts)
```

### Standard internal layout of EACH Django app
Every app under `khatir/` follows the same shape:
```
<appname>/
├── __init__.py
├── apps.py
├── models.py              ORM models (or models/ package if large)
├── enums.py               App-specific TextChoices
├── managers.py            Custom managers with for_user() scoping
├── serializers.py         DRF serializers
├── services.py            Business logic (views call this)
├── selectors.py           Read queries (optional, for complex reads)
├── permissions.py         App-specific DRF permissions
├── views.py               Thin DRF views/viewsets
├── urls.py                App URL conf
├── tasks.py               Celery tasks (if any)
├── admin.py               Django admin registration
├── migrations/
└── tests/
    ├── __init__.py
    ├── test_models.py
    ├── test_services.py
    ├── test_views.py
    └── factories.py       factory-boy factories
```

---

## 3. `apps/mobile/` — Flutter app

**Folder-by-feature.** Each feature owns its data/domain/presentation.

```
apps/mobile/
├── pubspec.yaml
├── analysis_options.yaml
├── l10n.yaml                  i18n config
├── lib/
│   ├── main.dart              Entry; ProviderScope + app bootstrap
│   ├── app.dart               MaterialApp.router + theme + locale
│   │
│   ├── core/
│   │   ├── router/
│   │   │   └── app_router.dart    ALL go_router routes
│   │   ├── theme/
│   │   │   ├── colors.dart        Notun Din palette
│   │   │   ├── text_styles.dart
│   │   │   └── app_theme.dart
│   │   ├── network/
│   │   │   ├── dio_client.dart    Single dio instance + interceptors
│   │   │   ├── api_endpoints.dart
│   │   │   └── api_exception.dart
│   │   ├── storage/
│   │   │   └── secure_storage.dart  Token storage
│   │   ├── enums/                  Shared dart enums (Role, etc.)
│   │   ├── widgets/                Shared widgets (KButton, KCard, KChip…)
│   │   └── utils/
│   │
│   ├── l10n/
│   │   ├── app_bn.arb             Bangla (default)
│   │   └── app_en.arb             English
│   │
│   └── features/
│       ├── onboarding/            Intro slides  (EPIC-01)
│       ├── auth/                  Phone+OTP  (EPIC-01)
│       ├── role/                  Role chooser  (EPIC-02)
│       ├── shell/                 Role-based bottom-nav shells (EPIC-02)
│       │   ├── landlord_shell.dart
│       │   ├── manager_shell.dart
│       │   └── tenant_shell.dart
│       ├── properties/            Buildings + units + add wizard  (EPIC-03)
│       ├── tenants/               Add tenant, OCR, voice  (EPIC-04)
│       ├── dmpform/               DMP form preview + PDF  (EPIC-05)
│       ├── rent/                  Rent request + collection  (EPIC-07)
│       ├── expenses/              Maintenance + expenses  (EPIC-08)
│       ├── dashboard/             Charts  (EPIC-09)
│       ├── tenant_home/           Tenant-side features  (EPIC-19, P1)
│       └── manager_home/          Manager portfolio  (EPIC-22, P1)
│
├── test/                          Mirror of lib/features
├── android/
└── ios/
```

### Standard internal layout of EACH Flutter feature
```
features/<feature>/
├── data/
│   ├── models/                 freezed models
│   ├── <feature>_repository.dart   API calls via dio
│   └── <feature>_providers.dart    Riverpod providers
├── domain/                     (optional) entities, use-cases if complex
└── presentation/
    ├── screens/                Full screens
    ├── widgets/                Feature-specific widgets
    └── controllers/            Riverpod notifiers / state
```

---

## 4. `apps/admin/` — Next.js admin portal

```
apps/admin/
├── package.json
├── next.config.ts
├── tailwind.config.ts
├── tsconfig.json
├── src/
│   ├── app/                    App Router
│   │   ├── layout.tsx
│   │   ├── login/
│   │   ├── (dashboard)/        Authenticated group
│   │   │   ├── layout.tsx      Sidebar + topbar
│   │   │   ├── dashboard/
│   │   │   ├── users/
│   │   │   ├── pricing/
│   │   │   ├── features/
│   │   │   ├── kill-switch/
│   │   │   ├── notifications/
│   │   │   ├── ai-providers/
│   │   │   ├── compliance/
│   │   │   ├── system/
│   │   │   └── admins/
│   │   └── api/                Route handlers (BFF proxy if needed)
│   │
│   ├── components/
│   │   ├── ui/                 Primitives (Button, Card, Table, Toggle…)
│   │   └── features/           Feature components
│   ├── lib/
│   │   ├── api/                Typed API client + zod schemas
│   │   ├── auth/               MFA session handling
│   │   └── utils/
│   ├── hooks/                  TanStack Query hooks
│   └── types/                  Shared TS types + enum unions
└── public/                     Favicon, logo assets
```

---

## 5. `docs/` — where documents live

```
docs/
├── architecture/
│   ├── 00_overview.md
│   ├── 01_stack_and_standards.md
│   ├── 02_project_structure.md   ← this file
│   ├── 03_env_and_config.md
│   ├── 04_coding_conventions.md
│   ├── 05_navigation_routing.md
│   ├── 06_database_schema.md
│   └── enums.md                  Canonical enum list (all 3 surfaces match)
│
├── product/                      Your existing specs (source of truth for WHAT)
│   ├── 01_BRD_Khatir.md
│   ├── 02_SRS_Khatir.md
│   ├── 03_Backlog_and_Flows_Khatir.md
│   └── 04_Admin_Portal_Khatir.md
│
├── logos/                        Your existing brand pack
│
└── epics/                        The work plan (source of truth for HOW + tracking)
    ├── README.md                 Master tracker dashboard
    ├── _master_plan.md           All epics in order + dependencies
    ├── _task_template.md         Strict task file template
    ├── _handoff_protocol.md      Agent-to-agent handoff rules
    ├── _glossary.md              Shared vocabulary
    ├── EPIC-00-foundation/
    │   ├── _epic.md
    │   ├── _checklist.md
    │   ├── T-001-....md
    │   └── ...
    ├── EPIC-01-onboarding-auth/
    └── ...
```

**Source-of-truth rule:**
- `docs/product/` = **WHAT** to build (business + requirements). Rarely changes.
- `docs/architecture/` = **HOW it's structured** (rules). Changes only via a deliberate decision.
- `docs/epics/` = **the executable plan + live status**. Changes constantly as work progresses.

---

## 6. Hard rules for agents

1. **Do not create new top-level folders.** Everything fits the map above.
2. **Do not put business logic in `views.py` (Django) or widgets (Flutter) or components (Next.js).** Logic → `services.py` / repositories / hooks.
3. **One Django app = one bounded context.** Don't cross-import models between apps; go through services.
4. **One Flutter feature = one folder under `features/`.** Shared things go to `core/`.
5. **Shared design tokens** live in `packages/design-tokens/` and are imported, never duplicated.
6. **Tenant web-link pages** are Django templates under `apps/api/templates/tenant_web/`, NOT a separate app.
