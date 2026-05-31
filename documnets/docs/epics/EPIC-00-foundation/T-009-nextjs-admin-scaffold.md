---
id: T-009
epic: EPIC-00
title: Next.js admin scaffold (App Router, Tailwind, shells)
layer: admin
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-001, T-010]
blocks: [T-011, T-013, T-014, T-015]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-009 · Next.js admin scaffold (App Router, Tailwind, shells)

## 1. Feature goal
Create the Next.js admin portal at `apps/admin/` with App Router, TypeScript strict, Tailwind themed to Notun Din (from shared tokens), TanStack Query + zod set up, a placeholder login page, and the authenticated dashboard shell (sidebar + topbar) — the base every admin module builds on.

## 2. Business logic
Follows `02_project_structure.md` (admin layout), `05_navigation_routing.md` (App Router structure + sidebar nav), and `01_stack_and_standards.md`. English-only UI (next-intl infra kept). No real auth yet (placeholder), no admin modules yet.

## 3. What this task DOES
- `create-next-app` (latest stable Next, App Router, TS, Tailwind) at `apps/admin/`.
- Tailwind config consuming the shared design-tokens (Notun Din palette).
- TanStack Query provider + a typed API client skeleton (`lib/api/`) with zod.
- App Router structure: `app/login/page.tsx` (placeholder form), `app/(dashboard)/layout.tsx` (sidebar + topbar shell with auth-guard stub), `app/(dashboard)/dashboard/page.tsx` (placeholder KPIs).
- Sidebar nav items matching admin spec §3.1 (links present, pages stubbed/coming-soon).
- Shared UI primitives in `components/ui/` (Button, Card, Table, Toggle, Chip) themed to tokens.
- Complete `infra/docker/admin.Dockerfile`; enable `admin` compose service.
- ESLint + Prettier; one component test (vitest/RTL or Playwright smoke).

## 4. What this task does NOT do
- No real auth/MFA (EPIC-11).
- No real admin modules (EPIC-12–16).

## 5. Files & changes
### Add
- `apps/admin/` full Next project (package.json, package-lock.json, tsconfig, next.config.ts, tailwind.config.ts, eslint, prettier)
- `src/app/layout.tsx`, `src/app/login/page.tsx`
- `src/app/(dashboard)/layout.tsx`, `src/app/(dashboard)/dashboard/page.tsx`
- `src/components/ui/{button,card,table,toggle,chip}.tsx`
- `src/lib/api/client.ts` (+ zod base), `src/lib/auth/guard.ts` (stub)
- `src/hooks/.gitkeep`, `src/types/enums.ts` (TS unions from enums.md — Role, AdminRole, etc.)
- `src/app/(dashboard)/_nav.ts` (sidebar items)
- one test file
### Update
- `infra/docker/admin.Dockerfile`, `docker-compose.yml` (enable admin)
### Delete
- create-next-app boilerplate sample content

## 6. Database changes
No DB changes.

## 7. API changes
Consumes the API; no new endpoints. API client points at `NEXT_PUBLIC_API_BASE_URL`.

## 8. UI changes
- Surface: admin
- Routes: `/login` (placeholder), `/(dashboard)/dashboard` (placeholder KPIs)
- Shell: sidebar (nav items from admin spec §3.1) + topbar; auth-guard stub redirects if no session
- States: loading + empty present on the dashboard placeholder

## 9. External services
None.

## 10. Feature flags
None.

## 11. Implementation checklist
- [ ] create-next-app latest stable, App Router, TS strict, Tailwind
- [ ] Tailwind themed from shared design-tokens (Notun Din)
- [ ] TanStack Query provider + zod-typed API client skeleton
- [ ] login placeholder page
- [ ] (dashboard) layout: sidebar + topbar + auth-guard stub
- [ ] dashboard placeholder with loading/empty states
- [ ] ui primitives (Button/Card/Table/Toggle/Chip)
- [ ] enums.ts TS unions match enums.md
- [ ] admin.Dockerfile + compose admin service
- [ ] eslint + prettier + tsc clean; test passes
- [ ] `npm run build` succeeds

## 12. Test plan
### Automated
- one render test for the dashboard shell (sidebar renders nav items)
### Manual QA
1. `npm run dev` → `/login` renders; visiting `/dashboard` without session redirects to `/login` (stub).

## 13. Acceptance criteria
- [ ] Admin builds + serves login + dashboard shell.
- [ ] Sidebar nav matches admin spec §3.1.
- [ ] tsc + eslint + build pass.

## 14. Self-review
- [ ] Tokens from shared package (no re-hardcoded palette)
- [ ] Server Components default; "use client" only where needed
- [ ] enums match enums.md
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Sidebar items (from admin spec §3.1): Dashboard, Users, Pricing, Features, Kill-switch, Notifications, AI providers, Compliance, System, Support, Admin users, Analytics, Security. Stub the not-yet-built ones as "Coming soon" pages.
- Keep auth as a stub that checks a fake session cookie; real MFA is EPIC-11.
- Admin UI language is English; keep next-intl installed but minimal.
