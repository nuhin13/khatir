# 05 · Navigation & Routing

> Flutter app navigation (go_router, role-based shells), Next.js admin routing, and API URL conventions. One source of truth so screens wire up consistently.

---

## 1. Flutter — go_router structure

All routes declared in `lib/core/router/app_router.dart`. No ad-hoc `Navigator.push` for primary navigation.

### Route tree
```
/                         → splash (decides next based on auth + role)
/onboarding               → intro slides (first launch only)
/auth/phone               → phone entry
/auth/otp                 → OTP verify
/role                     → role chooser (after first OTP, if role unset)

# Role-based shells (StatefulShellRoute — bottom nav per role)
/landlord                 → LandlordShell
  /landlord/home          → landlord home (DMP CTA, portfolio)
  /landlord/dashboard     → charts
  /landlord/rent          → rent collection
  /landlord/more          → settings, profile, about

/manager                  → ManagerShell
  /manager/home           → multi-owner portfolio
  /manager/dashboard      → aggregate report
  /manager/rent           → rent across owners
  /manager/more

/tenant                   → TenantShell
  /tenant/home            → rent due, lease, receipts
  /tenant/maintenance     → request maintenance
  /tenant/receipts        → receipt history
  /tenant/more

# Pushed (full-screen) routes — above the shell
/properties/add           → 4-step add-building wizard (name+area → address+map → units → review)
/properties/:id           → building detail
/tenants/add              → method chooser
/tenants/add/ocr          → NID camera + extract
/tenants/add/voice        → voice fill
/tenants/add/manual       → manual form
/dmpform/:id              → DMP form preview
/dmpform/:id/pdf          → PDF view/share
/rent/request             → rent request composer
/rent/:id/verify          → verify payment proof
/expenses                 → expense + maintenance list
/expenses/add             → manual expense
/verify/:tenantId         → NID verification (P1)
/settings                 → settings
```

### Role routing rule
- After OTP, `/splash` reads `user.role`:
  - `landlord` → `/landlord/home`
  - `manager` → `/manager/home`
  - `tenant` → `/tenant/home`
  - role unset → `/role`
- A `redirect` guard in go_router enforces: unauthenticated → `/auth/phone`; authenticated without role → `/role`; wrong-role access to a shell → bounce to own shell home.

### Shells (StatefulShellRoute)
Each role shell owns its bottom-nav with role-specific tabs. Branches keep their own navigation stack. The three shells are separate widgets (`landlord_shell.dart`, etc.) but share the `KBottomNav` component styled with Notun Din tokens.

### Deep links (for tenant web-link handoff & notifications)
- `khatir://rent/:token` → opens rent proof flow (if app installed).
- `https://khatir.com.bd/r/:token` → universal link; opens app if installed, else the web page.
- Notification taps route via go_router named routes with extra params.

### Navigation conventions
- Tab switches: `context.goNamed(...)` (replaces branch).
- Forward push: `context.pushNamed(...)` (full-screen, has back).
- Back: `context.pop()`.
- Never construct `MaterialPageRoute` manually for app routes.
- Pass typed params via go_router `extra` with a freezed args class, not loose maps.

---

## 2. Next.js admin — App Router structure

```
src/app/
├── layout.tsx                 Root (fonts, providers)
├── login/page.tsx             Email + password + MFA
├── (dashboard)/               Authenticated route group
│   ├── layout.tsx             Sidebar + topbar shell (auth guard here)
│   ├── dashboard/page.tsx
│   ├── users/
│   │   ├── page.tsx           List
│   │   └── [id]/page.tsx      Detail
│   ├── pricing/page.tsx
│   ├── features/page.tsx
│   ├── kill-switch/page.tsx
│   ├── notifications/
│   │   ├── page.tsx           Compose (default tab)
│   │   ├── history/page.tsx
│   │   └── templates/page.tsx
│   ├── ai-providers/page.tsx
│   ├── compliance/
│   │   ├── audit/page.tsx
│   │   ├── consent/page.tsx
│   │   └── data-requests/page.tsx
│   ├── system/page.tsx
│   └── admins/page.tsx
└── api/                       Route handlers (only if a BFF proxy is needed)
```

### Admin routing conventions
- Auth guard in `(dashboard)/layout.tsx`: no valid MFA session → redirect to `/login`.
- Sidebar nav items map 1:1 to top-level dashboard routes (matches admin spec §3.1).
- Server Components fetch initial data; client components handle interactivity via TanStack Query.
- URL is the source of truth for filters (e.g. `/users?role=landlord&status=active`) — use `searchParams`.

---

## 3. API URL conventions (recap from conventions doc)

```
/api/v1/<resource>                     domain resources
/api/v1/<resource>/<id>
/api/v1/<resource>/<id>/<subresource>  one level nesting max
/api/v1/admin/<resource>               admin-only
/api/v1/config/public                  client bootstrap config + feature flags
/api/v1/auth/request-otp
/api/v1/auth/verify-otp
/api/v1/auth/refresh
/r/<token>                             tenant web-link (HTML, not /api)
/healthz                               health check (no auth)
```

---

## 4. Auth flow across surfaces

### Mobile
1. `POST /auth/request-otp { phone }` → 200 (OTP sent / logged in dev).
2. `POST /auth/verify-otp { phone, code }` → `{ access, refresh, user }`.
3. Tokens in `flutter_secure_storage`. `dio` interceptor attaches `Authorization: Bearer`.
4. On 401, interceptor tries `POST /auth/refresh`; on failure routes to `/auth/phone`.

### Admin
1. `POST /admin/auth/login { email, password }` → MFA challenge.
2. `POST /admin/auth/mfa { token }` → session cookie (httpOnly) or short JWT.
3. Session guard in dashboard layout. Idle timeout 30 min, max 8 hr.

### Tenant web-link
- No auth. Token in URL (`/r/<token>`) is a signed, single-purpose, expiring token bound to one RentRequest. Validated server-side; no account created.

---

## 5. Navigation flow diagrams (reference for UI tasks)

### First launch → role
```
splash → onboarding(3 slides) → auth/phone → auth/otp
       → (role unset?) → role → [landlord|manager|tenant] home
```

### Landlord core loop (the wedge)
```
landlord/home → tenants/add → tenants/add/ocr → (extract)
             → dmpform/:id → dmpform/:id/pdf → (share) → landlord/home
```

### Rent collection
```
landlord/home → rent/request → (send) → [confirmation]
   ... tenant opens web-link /r/:token → uploads proof ...
landlord notification → rent/:id/verify → (received) → receipt → landlord/home
```

Each UI task references the relevant flow here plus the matching screen in `docs/product` JSX prototypes.

---

## 6. Rules for agents

1. New screen → add a route in `app_router.dart` (Flutter) or a folder under `app/` (Next.js). Never hardcode navigation outside the router.
2. Route params are typed (freezed args / typed searchParams), never loose maps.
3. Role guards live in the router redirect, not scattered in screens.
4. Deep-link and notification routes reuse the same named routes.
5. Tenant web-link is server-rendered HTML under `/r/`, never part of the Flutter app or admin.
