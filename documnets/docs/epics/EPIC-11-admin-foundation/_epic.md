# EPIC-11 · Admin Portal Foundation

**Phase:** MVP · **Status:** todo · **Depends on:** EPIC-00 (parallel with mobile MVP)
**Tasks:** 12 · **External services:** none (TOTP MFA local)

---

## Business goal
Stand up the Next.js admin portal with its own auth (email + MFA), the dashboard shell, sidebar navigation, and the audit-log plumbing that every other admin module uses. The control room for running Khatir.

## User-visible outcome
An internal staff member visits `admin.khatir.app`, logs in with email + 6-digit TOTP code, and lands on the platform dashboard (KPI tiles, activity feed, health checks). From the sidebar they can navigate to every admin module (most "coming soon" until EPIC-12–16 build them out).

## Scope
**In scope**
- `AdminUser` model (separate from `User`; email+password+TOTP MFA; roles: super/ops/finance/compliance/support).
- Login + MFA flow (Next.js side + backend auth).
- Authenticated session with timeout.
- Platform dashboard (counts, activity, health).
- Sidebar + topbar shell with all nav items (later epics fill the pages).
- `AdminAuditEntry` infra + a viewer in the UI.
- Role-based admin access (which sections each role can see).

**Out of scope**
- Individual admin modules (EPIC-12–16).
- Customer-facing User management in detail (EPIC-12).
- Notification sending (EPIC-15).

## Dependencies
- **Prerequisite:** EPIC-00 (Next.js admin scaffold from T-009 already built; this completes it with real auth).
- **Parallel with:** the mobile MVP (EPIC-01–10). Admin can build independently.
- **External:** none (TOTP uses a library like `otplib`; no external auth provider needed).
- **Design:** `ui/KhatirAdmin.jsx` + `docs/product/04_Admin_Portal_Khatir.md`. (No mobile prototype screens — this is Next.js only.)

## Data-model changes
- `AdminUser` (separate table from `User`): email, name, password_hash, totp_secret_enc, role AdminRole, scope, disabled, last_login_at.
- `AdminAuditEntry`: admin_user, action, entity_type, entity_id, before_json, after_json, ip, reason, created_at.
- AdminRole enum: super/ops/finance/compliance/support.

## API surface (admin-only, separate prefix `/admin/api/`)
- `POST /admin/api/auth/login` — email+password → challenge (if MFA) or session token.
- `POST /admin/api/auth/verify-mfa` — TOTP code → session token.
- `POST /admin/api/auth/logout`.
- `GET /admin/api/auth/me`.
- `GET /admin/api/dashboard` — platform KPIs.
- `GET /admin/api/audit-log` — paginated audit log with filters.

## UI screens (admin — 🟣 Next.js)
No mobile prototype screens. Design source: `docs/product/04_Admin_Portal_Khatir.md` + `ui/KhatirAdmin.jsx`.
- `/login` (already scaffolded in EPIC-00; this wires real auth)
- `/(dashboard)/dashboard` (platform KPIs)
- `/(dashboard)/audit` (audit log viewer)

## Feature flags introduced
None.

## Admin-portal config keys
- `admin_session_timeout_minutes` (int, default 60).
- `admin_mfa_required` (bool, default true).

## Test strategy
- Backend: login flow (correct/wrong password, MFA correct/wrong, account disabled); session timeout; role-based endpoint access; audit on every admin action.
- Admin Next.js: login form submits; MFA step; session guard redirects; dashboard KPIs; audit log table with filters.

## Acceptance criteria (epic-level)
- [ ] Admin can log in with email + TOTP; wrong MFA blocked; disabled accounts blocked.
- [ ] Session expires per config; logout clears session.
- [ ] Platform dashboard shows real KPIs (user/property/revenue counts).
- [ ] Every admin write creates an AdminAuditEntry.
- [ ] Sidebar nav matches admin spec §3.1; all non-built pages show "coming soon."
- [ ] Role-based access: compliance role can't access pricing, etc.
- [ ] `make test` + `make lint` pass for api + admin.

## Task list
| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | AdminUser model + enums + migration | backend | M | EPIC-00.T-005 |
| T-002 | AdminAuditEntry model + audit writer | backend | M | T-001 |
| T-003 | Admin auth endpoints (login, MFA, logout, me) | backend | M | T-001 |
| T-004 | Admin role-based permissions | backend | S | T-001 |
| T-005 | Platform dashboard API endpoint | backend | M | T-001 |
| T-006 | Seed admin session config | backend | XS | EPIC-00.T-005 |
| T-007 | Admin login + MFA screen (Next.js) | admin | M | T-003 |
| T-008 | Authenticated shell + session guard | admin | M | T-007 |
| T-009 | Platform dashboard page | admin | M | T-005, T-008 |
| T-010 | Sidebar navigation + coming-soon stubs | admin | S | T-008 |
| T-011 | Audit log viewer page | admin | M | T-002, T-008 |
| T-012 | Seed first AdminUser (setup script) | backend | XS | T-001 |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| TOTP secret leakage | Encrypt at rest (core.encryption); never log; QR code shown once |
| Admin bypass mobile auth | Completely separate model, table, endpoints, JWT signing key |
| Role misconfiguration | Tests assert each role can/cannot access each section |
| Session fixation | Rotate session token on every login + MFA |
