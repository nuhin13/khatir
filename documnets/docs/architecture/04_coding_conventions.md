# 04 · Coding Conventions

> Naming, API envelope, errors, multi-tenancy, i18n, datetime, money. These are the cross-cutting rules every task inherits.

---

## 1. API design

### Base path & versioning
All API routes under `/api/v1/`. Version bumps only on breaking changes.

### Resource naming
- Plural nouns: `/buildings`, `/tenants`, `/rent-requests`.
- Kebab-case multi-word: `/rent-requests`, `/payment-proofs`.
- Nested only one level deep: `/buildings/{id}/units`. Beyond that, use query params: `/units?building_id=X`.
- Admin endpoints under `/api/v1/admin/...`.

### Methods & status codes
| Action | Method | Success |
|--------|--------|---------|
| List | GET | 200 |
| Retrieve | GET | 200 |
| Create | POST | 201 |
| Full update | PUT | 200 |
| Partial update | PATCH | 200 |
| Delete | DELETE | 204 |

### Standard response envelope
**Success** — return the resource/data directly (DRF default), but lists are paginated (see §2):
```json
{ "id": "...", "name": "...", ... }
```
**Error** — always this shape (custom exception handler in `core/exceptions.py`):
```json
{
  "error": {
    "code": "validation_error",
    "message": "Human-readable, already localized when user-facing.",
    "details": { "field_name": ["specific issue"] }
  }
}
```
Error `code` is a stable machine string (enum). Clients switch on `code`, show `message`.

### Error code enum (canonical, in `core/enums.py`)
```
validation_error · not_found · permission_denied · auth_required ·
auth_invalid · conflict · rate_limited · upstream_unavailable ·
feature_disabled · payment_required · server_error
```

---

## 2. Pagination

All list endpoints paginated. Cursor pagination for large/append-only sets (audit log, notifications), page-number for small admin tables.
```json
{
  "results": [ ... ],
  "pagination": { "next": "cursor_or_url", "previous": null, "count": 142 }
}
```
Default page size 20, max 100 (`?page_size=`).

---

## 3. Multi-tenancy & row-level isolation (critical)

**Every domain model that belongs to a user is filtered through a `for_user()` manager method.** Views never query `.objects.all()` on domain data.

```python
# managers.py
class BuildingQuerySet(models.QuerySet):
    def for_user(self, user):
        if user.role == Role.LANDLORD:
            return self.filter(owner=user)
        if user.role == Role.MANAGER:
            return self.filter(owner__in=user.managed_owner_ids())
        return self.none()   # tenants don't list buildings

# view
buildings = Building.objects.for_user(request.user)
```

**Rule:** a missing `for_user()` scope is a P0 security bug and fails review automatically. Tenants accessing data they don't own must get 404 (not 403 — don't reveal existence).

---

## 4. Permissions

DRF permission classes, named by intent, in each app's `permissions.py`:
```python
class IsLandlord(BasePermission): ...
class IsOwnerOfBuilding(BasePermission): ...
class IsManagerOfOwner(BasePermission): ...
class IsTenantOfLease(BasePermission): ...
class IsAdminRole(BasePermission): ...   # admin portal, checks AdminUser + role
```
Compose with `&`/`|`. Never inline permission logic in a view body.

---

## 5. Services & selectors pattern

- **`services.py`** — write operations + business logic. Functions, not classes (unless state needed). One public function per use-case:
  ```python
  def create_tenant_from_ocr(*, user, unit_id, ocr_payload) -> Tenant: ...
  def verify_rent_payment(*, user, rent_request_id) -> Payment: ...
  ```
- **`selectors.py`** — non-trivial reads. Keeps query logic out of views/serializers.
- Views call services/selectors, serialize the result, return. That's it.
- Services raise typed exceptions from `core/exceptions.py`; the handler maps them to the error envelope.

---

## 6. Naming

| Thing | Convention | Example |
|-------|-----------|---------|
| Python module/func/var | snake_case | `create_rent_request` |
| Python class | PascalCase | `RentRequest` |
| Django model field | snake_case | `due_date` |
| DRF serializer | `<Model>Serializer` | `TenantSerializer` |
| Service function | verb_noun | `generate_dmp_pdf` |
| Dart class | PascalCase | `RentRequest` |
| Dart file | snake_case | `rent_request.dart` |
| Dart var/func | camelCase | `fetchRentRequests` |
| Riverpod provider | `<noun>Provider` | `tenantListProvider` |
| TS type/interface | PascalCase | `PricingTier` |
| TS file | kebab or camel | `pricing-tier.ts` |
| API field (wire) | snake_case | `due_date` |
| Enum wire value | lower snake_case | `past_due` |
| Env var | UPPER_SNAKE | `JWT_SIGNING_KEY` |
| Feature flag key | lower_snake | `nid_verification` |
| Branch | `epic-NN/T-XXX-slug` | `epic-04/T-007-nid-ocr` |

**Wire format is always snake_case.** Flutter/TS convert to their local casing at the model boundary (freezed `@JsonKey`, zod transforms) — the API never emits camelCase.

---

## 7. Datetime & timezone

- Store **UTC**, always tz-aware. `USE_TZ = True`.
- API emits ISO-8601 with offset: `2026-05-31T09:00:00Z`.
- Display timezone is **Asia/Dhaka (UTC+6)** — conversion happens client-side, never in stored data.
- "Due day" type fields (rent due on the 5th) are stored as an int day-of-month, resolved to a concrete date per period in the rent scheduler.

---

## 8. Money

- Backend: `DecimalField(max_digits=12, decimal_places=2)`. Currency is BDT everywhere (no multi-currency in scope).
- Wire: string to avoid float drift — `"22000.00"`.
- Dart: parse to `Decimal` (package:decimal) or int paisa; never `double` for money.
- Display: `৳` prefix, Bangla numerals optional per user locale.

---

## 9. i18n

- **Backend:** user-facing messages (errors, notification bodies) localizable. Default `bn`. Use Django's translation for server-generated user text; notification templates carry both `_bn` and `_en` columns.
- **Flutter:** every string via ARB (`app_bn.arb` default, `app_en.arb`). No literals in widgets. Key naming: `feature_screen_element` e.g. `auth_otp_resend_button`.
- **Admin (Next.js):** English-only UI, but keep `next-intl` infra so it's not a rewrite later.
- **Numbers:** support Bangla numerals (`২৬,০০০`) in the mobile app via intl locale formatting; never hand-roll digit conversion.

---

## 10. Logging & observability

- Structured logging (JSON in prod, pretty in dev). Never `print()`.
- Log levels: ERROR (alerting), WARNING (degraded but handled), INFO (state changes), DEBUG (dev only).
- **Never log:** full NID numbers, OTP codes, JWT tokens, API keys, payment proof image contents. Mask: `nid=****7788`.
- Every external call (WhatsApp, SMS, AI gateway, EC API) logs: provider, latency, outcome — feeds usage tracking.
- Sentry captures unhandled exceptions in all 3 apps with environment tag.

---

## 11. Audit logging

Any create/update/delete on personal/sensitive data writes an `AuditEntry` via `core/audit.py`:
```python
audit(actor=user, action="tenant.create", target=tenant, before=None, after=snapshot(tenant))
```
Action strings are `domain.verb` (`tenant.create`, `rent.verify`, `killswitch.toggle`, `pricing.update`). Admin actions write `AdminAuditEntry` with before/after JSON diff. This is not optional — tasks touching personal data include an audit checklist item.

---

## 12. Feature flags

- Read via `is_enabled("nid_verification", user=...)` from `featureflags` app (cached).
- A disabled feature's endpoints return `403 feature_disabled`; its UI is hidden client-side based on `GET /api/v1/config/public` flags.
- Kill-switch = a special protected flag set that, when off, hides the feature instantly across clients.

---

## 13. Flutter-specific

- One screen = one file under `presentation/screens/`. Widgets it owns go in `presentation/widgets/`.
- State: Riverpod `AsyncNotifier` for screens with server data. Expose `AsyncValue<T>` so loading/error/data are explicit.
- Every screen handles all four states: loading (skeleton/spinner), error (retry), empty (friendly empty state), data.
- Repositories return domain models, throw `ApiException`. Controllers catch and map to `AsyncValue.error`.
- No business logic in widgets — push to controllers/repositories.

---

## 14. Next.js-specific

- Server Components by default. `"use client"` only for interactive leaves.
- All server data via TanStack Query hooks in `hooks/`, calling typed client in `lib/api/`.
- Validate every API response with zod before use.
- Tables/forms use the shared `components/ui/` primitives.
- Admin mutations show optimistic state + toast + audit confirmation where relevant (pricing, kill-switch).

---

## 15. Definition of Done (applies to every task)

A task is done when:
1. All implementation-checklist items checked.
2. `make test` passes for the affected app(s).
3. `make lint` passes (ruff / dart analyze / eslint).
4. Type checks pass (mypy / dart / tsc).
5. New/changed endpoints documented in `docs/architecture/api.md` (generated or hand-kept).
6. i18n strings exist in `bn` + `en` (mobile).
7. Audit added for personal-data writes.
8. Loading/error/empty states present (UI tasks).
9. Self-review block filled in the task file.
10. Status set to `review-requested`.
