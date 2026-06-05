# 07 · Design Map (screen → task → prototype)

> The single source of truth connecting every UI task to the exact screen in the Khatir design prototype. When a UI task says "build screen X," this map tells the agent precisely which prototype screen to translate. The prototype is the **visual/layout truth**; the **design-tokens package is the value truth** (colors/spacing/radii) — see §Rules.

---

## The design source

The Khatir mobile + role UIs are designed in a **Claude Design prototype**, available two ways (use whichever fits your tool):

1. **Claude Design (live):** `https://claude.ai/design/p/95a5aed6-a19d-4484-a3f0-8267f8c68ac8?file=khatir%2FKhatir+Mobile+Prototype.html` — open in your account; reference the file `khatir/Khatir Mobile Prototype.html`.
2. **Exported source (in-repo):** the prototype export lives at `docs/design/khatir-ui/` with the real screens defined in `proto/*.js`:
   - `proto/screens-onboard.js` — splash, intro, login, otp, roleChooser
   - `proto/screens-landlord.js` — home, addBuilding, portfolio, unit
   - `proto/screens-landlord2.js` — addTenant, ocr, voice, manualTenant, dmp, dmpPdf, rentReq, verifyPay, receipt, expenses, addExpense, dashboard, more, verify, lease, warning, plan
   - `proto/screens-other.js` — manager, tenant, web-link, caretaker screens
   - `proto/proto.css` — the prototype's CSS tokens (match `packages/design-tokens`)
   - `proto/ui.js` — shared helpers (statusbar, topbar, k-btn, k-card, k-chip, emojiHero, iconBadge…)

**How screens are identified:** each screen registers via `reg('<screenKey>', { group, en, bn, render(){…} })`. The `<screenKey>` is the anchor this map uses (e.g. `otp`, `addTenant`, `dmpPdf`). To view a screen in the exported source, search the relevant `proto/*.js` for `reg('<screenKey>'`.

> `proto/home-variants.js` is **exploration only** (three visual directions on the canvas). The **canonical** home is `reg('home')` in `screens-landlord.js` (Direction A "Warm"). Ignore the variants for production.

---

## How a UI task references a screen

Every UI task's §8 names the screen key. To build it:

1. Open the screen — Claude Design file `khatir/Khatir Mobile Prototype.html`, or in-repo `docs/design/khatir-ui/proto/<file>.js` → search `reg('<screenKey>'`.
2. Translate **layout + composition + copy** (including the Bangla/English strings, which become ARB entries) into Flutter.
3. Take **all colors, spacing, radii, shadows, fonts from `packages/design-tokens`** — never copy the prototype's inline hex/px. The prototype's CSS tokens already match the package, so the result is identical but maintainable.
4. Reproduce the four states (loading/error/empty/data) even if the prototype only shows the data state.

§8 format in tasks:
```markdown
## 8. UI changes
- Design source: screen `otp` — Claude Design `khatir/Khatir Mobile Prototype.html`
  (in-repo: docs/design/khatir-ui/proto/screens-onboard.js → reg('otp'))
- Route: /auth/otp   ·   Lane: 🟢 mobile
- Translate layout/composition + copy; values from packages/design-tokens
- States: loading/error/empty/data
```

---

## Master screen → task map

Lane legend: 🟢 mobile (Flutter) · 🟣 admin (Next.js) · 🌐 tenant web-link (served by API, Django template) — **not** the Flutter app.

### Onboarding & Auth → EPIC-01
| Screen key | en / bn | Route | Lane | Epic · Task | Prototype file |
|-----------|---------|-------|------|-------------|----------------|
| `splash` | Splash | `/` | 🟢 | EPIC-01 · T-012 | screens-onboard.js |
| `intro` | Intro slides (3) | `/onboarding` | 🟢 | EPIC-01 · T-008 | screens-onboard.js |
| `login` | Phone + OTP | `/auth/phone` | 🟢 | EPIC-01 · T-009 | screens-onboard.js |
| `otp` | Verify OTP | `/auth/otp` | 🟢 | EPIC-01 · T-010 | screens-onboard.js |
| `roleChooser` | Role chooser | `/role` | 🟢 | EPIC-02 · (role task) | screens-onboard.js |

### Role shells & profile → EPIC-02
| Screen | en / bn | Route | Lane | Epic · Task | File |
|--------|---------|-------|------|-------------|------|
| (shells) | Landlord/Manager/Tenant bottom-nav | `/landlord`,`/manager`,`/tenant` | 🟢 | EPIC-02 | derived from `home`, `mgrHome`, `tenHome` + `ui.js` nav |
| `more` | More menu (profile, language, about) | `/landlord/more` | 🟢 | EPIC-02 | screens-landlord2.js |

### Properties & Units → EPIC-03
| Screen | en / bn | Route | Lane | Epic · Task | File |
|--------|---------|-------|------|-------------|------|
| `home` | Home dashboard (landlord) | `/landlord/home` | 🟢 | EPIC-03 (home), EPIC-09 (charts) | screens-landlord.js |
| `addBuilding` | Add building (4-step wizard) | `/properties/add` | 🟢 | EPIC-03 | screens-landlord.js |
| `portfolio` | Portfolio | `/landlord/home` (list) | 🟢 | EPIC-03 | screens-landlord.js |
| `unit` | Unit detail | `/properties/unit/:id` | 🟢 | EPIC-03 | screens-landlord.js |

### Tenants & NID OCR → EPIC-04
| Screen | en / bn | Route | Lane | Epic · Task | File |
|--------|---------|-------|------|-------------|------|
| `addTenant` | Add tenant (method chooser) | `/tenants/add` | 🟢 | EPIC-04 | screens-landlord2.js |
| `ocr` | NID OCR scan | `/tenants/add/ocr` | 🟢 | EPIC-04 | screens-landlord2.js |
| `voice` | Voice fill | `/tenants/add/voice` | 🟢 | EPIC-04 | screens-landlord2.js |
| `manualTenant` | Manual DMP form | `/tenants/add/manual` | 🟢 | EPIC-04 | screens-landlord2.js |

### DMP Form → EPIC-05
| Screen | en / bn | Route | Lane | Epic · Task | File |
|--------|---------|-------|------|-------------|------|
| `dmp` | DMP form (review) | `/dmpform/:id` | 🟢 | EPIC-05 | screens-landlord2.js |
| `dmpPdf` | DMP PDF preview | `/dmpform/:id/pdf` | 🟢 | EPIC-05 | screens-landlord2.js |

### Lease & Rent → EPIC-06 / EPIC-07
| Screen | en / bn | Route | Lane | Epic · Task | File |
|--------|---------|-------|------|-------------|------|
| `rentReq` | Rent request | `/rent/request` | 🟢 | EPIC-07 | screens-landlord2.js |
| `verifyPay` | Verify payment | `/rent/:id/verify` | 🟢 | EPIC-07 | screens-landlord2.js |
| `receipt` | Receipt | `/rent/:id/receipt` | 🟢 | EPIC-07 | screens-landlord2.js |
| (lease screens) | Lease create/list | `/lease/...` | 🟢 | EPIC-06 | derived; see `lease` for AI-lease P1 |

### Maintenance & Expenses → EPIC-08
| Screen | en / bn | Route | Lane | Epic · Task | File |
|--------|---------|-------|------|-------------|------|
| `expenses` | Maintenance & expenses | `/expenses` | 🟢 | EPIC-08 | screens-landlord2.js |
| `addExpense` | Add expense | `/expenses/add` | 🟢 | EPIC-08 | screens-landlord2.js |

### Dashboard → EPIC-09
| Screen | en / bn | Route | Lane | Epic · Task | File |
|--------|---------|-------|------|-------------|------|
| `dashboard` | Dashboard / charts | `/landlord/dashboard` | 🟢 | EPIC-09 | screens-landlord2.js |

### Pricing → EPIC-10
| Screen | en / bn | Route | Lane | Epic · Task | File |
|--------|---------|-------|------|-------------|------|
| `plan` | Plan & billing | `/settings/plan` | 🟢 | EPIC-10 | screens-landlord2.js |

### Manager (B2B) → EPIC-22 (P1)
| Screen | en / bn | Route | Lane | Epic · Task | File |
|--------|---------|-------|------|-------------|------|
| `mgrHome` | Manager home | `/manager/home` | 🟢 | EPIC-22 | screens-other.js |
| `mgrAddOwner` | Add owner | `/manager/owners/add` | 🟢 | EPIC-22 | screens-other.js |
| `mgrTeam` | Team members | `/manager/team` | 🟢 | EPIC-22 | screens-other.js |
| `mgrReport` | Consolidated report | `/manager/dashboard` | 🟢 | EPIC-22 | screens-other.js |

### Tenant app → EPIC-19 (P1)
| Screen | en / bn | Route | Lane | Epic · Task | File |
|--------|---------|-------|------|-------------|------|
| `tenHome` | Tenant home | `/tenant/home` | 🟢 | EPIC-19 | screens-other.js |
| `tenLease` | Lease detail | `/tenant/lease` | 🟢 | EPIC-19 | screens-other.js |
| `tenPay` | Pay rent | `/tenant/pay` | 🟢 | EPIC-19 | screens-other.js |
| `tenMaint` | Request maintenance | `/tenant/maintenance` | 🟢 | EPIC-19 | screens-other.js |
| `tenReceipts` | Receipts | `/tenant/receipts` | 🟢 | EPIC-19 | screens-other.js |
| `tenReview` | Review landlord | `/tenant/review` | 🟢 | EPIC-21 | screens-other.js |
| `tenRecord` | Good-tenant record | `/tenant/record` | 🟢 | EPIC-21 | screens-other.js |

### Tenant web-link (no install) → EPIC-07 / EPIC-25 · served by API (Django templates)
| Screen | en / bn | Route | Lane | Epic · Task | File |
|--------|---------|-------|------|-------------|------|
| `webPay` | Rent pay link | `/r/:token` | 🌐 | EPIC-07 | screens-other.js |
| `webReceipt` | Receipt view | `/r/:token/receipt` | 🌐 | EPIC-07 | screens-other.js |
| `webMaint` | Maintenance form | `/m/:token` | 🌐 | EPIC-08/19 | screens-other.js |
| `webVisitor` | Visitor QR form | `/v/:token` | 🌐 | EPIC-25 | screens-other.js |

### Caretaker / Gatekeeper → EPIC-25 (P2)
| Screen | en / bn | Route | Lane | Epic · Task | File |
|--------|---------|-------|------|-------------|------|
| `careHome` | Caretaker home | `/caretaker/home` | 🟢 | EPIC-25 | screens-other.js |
| `careReview` | Visitor review | `/caretaker/review` | 🟢 | EPIC-25 | screens-other.js |
| `careLog` | Visitor log | `/caretaker/log` | 🟢 | EPIC-25 | screens-other.js |

### P1 landlord-side additions
| Screen | en / bn | Route | Lane | Epic · Task | File |
|--------|---------|-------|------|-------------|------|
| `verify` | NID verify | `/verify/:tenantId` | 🟢 | EPIC-17 | screens-landlord2.js |
| `lease` | AI lease | `/lease/generate` | 🟢 | EPIC-18 | screens-landlord2.js |
| `warning` | Warning / complaint | `/warning/...` | 🟢 | EPIC-20 | screens-landlord2.js |

### Admin portal → EPIC-11–16 (🟣 Next.js)
The admin portal is **not** in this mobile prototype. Its design source is `docs/design/khatir-ui/uploads/Khatir/ui/KhatirAdmin.jsx` plus the admin spec `docs/product/04_Admin_Portal_Khatir.md`. Admin screens (dashboard, users, pricing, features, kill-switch, notifications, ai-providers, compliance, system, admins) map to EPIC-11–16 and reference those two sources.

---

## Shared UI primitives (build once, in EPIC-00 T-008 / reuse everywhere)

The prototype's `proto/ui.js` defines reusable pieces. These become the Flutter shared widgets in `lib/core/widgets/` (started in EPIC-00 T-008):

| Prototype helper | Flutter widget | Purpose |
|------------------|----------------|---------|
| `statusbar()` | (system) | phone status bar — native |
| `topbar({...})` | `KTopBar` | screen header w/ optional brand/back/action |
| `k-btn` (primary/ghost/soft/full/lg) | `KButton` | buttons |
| `k-card` | `KCard` | rounded card container |
| `k-chip` | `KChip` | status/label chips |
| `k-field` | `KField` | form input |
| `k-track` | `KProgressTrack` | progress bar |
| `emojiHero()` | `KEmojiHero` | big emoji header block |
| `iconBadge()` / `kicon()` | `KIconBadge` | icon-in-rounded-square |
| bottom nav | `KBottomNav` | role shell nav (EPIC-02) |

When a screen task needs one of these, it uses the shared widget — it does not re-implement it.

---

## Rules (enforced in UI-task review)

1. **Prototype = layout truth; tokens = value truth.** Match the prototype's composition, but pull every color/spacing/radius/shadow/font from `packages/design-tokens`. Never hardcode the prototype's inline hex/px. (They already match, so output is identical and stays maintainable.)
2. **Copy is design, too.** The Bangla + English strings in the prototype are the real copy — lift them into ARB (`bn` + `en`) verbatim unless the task says otherwise.
3. **All four states.** The prototype shows the data state; the Flutter screen must also handle loading/error/empty.
4. **Shared widgets over re-implementation.** Use `lib/core/widgets/` primitives that mirror `proto/ui.js`.
5. **One screen key = one task §8 anchor.** If a task builds multiple screens, list each key.
6. **Web-link screens are Django templates**, not Flutter — see the 🌐 rows.
7. **Coverage gate (below) is mandatory.** No epic is `verified` until every screen the ledger assigns to it has a concrete `T-XXX` that builds it. No screen may be silently dropped.

---

## ⭐ Screen Coverage Ledger (the source-of-truth gate)

> **Purpose:** guarantee that *every one of the 44 prototype screens* is built by a concrete task — none forgotten. This ledger is authoritative. When an epic is written, it MUST create a task for every screen assigned to it here, then fill the `Task` column. When an epic is reviewed for completion, every one of its ledger rows must show a real `T-XXX` and that task must be `done`/`verified`. A screen with no task = epic cannot close.

**Total prototype screens: 44.** (Counted directly from `reg('…')` across all `proto/*.js`. `home-variants.js` registers nothing — it is canvas-only exploration.)

| # | Screen key | en / bn | Group / role | Prototype file | Epic | Task | Built? |
|---|-----------|---------|--------------|----------------|------|------|--------|
| 1 | `splash` | Splash | Onboarding | screens-onboard.js | EPIC-01 | T-012 | ☐ |
| 2 | `intro` | Intro slides | Onboarding | screens-onboard.js | EPIC-01 | T-008 | ☐ |
| 3 | `login` | Phone + OTP | Onboarding | screens-onboard.js | EPIC-01 | T-009 | ☐ |
| 4 | `otp` | Verify OTP | Onboarding | screens-onboard.js | EPIC-01 | T-010 | ☐ |
| 5 | `roleChooser` | Role chooser | Onboarding | screens-onboard.js | EPIC-02 | T-005 | ☐ |
| 6 | `home` | Home dashboard | Landlord | screens-landlord.js | EPIC-03 (T-009) + EPIC-09 (charts) | T-009 | ☐ |
| 7 | `addBuilding` | Add building (4-step) | Landlord | screens-landlord.js | EPIC-03 | T-010,T-011 | ☐ |
| 8 | `portfolio` | Portfolio | Landlord | screens-landlord.js | EPIC-03 | T-012 | ☐ |
| 9 | `unit` | Unit detail | Landlord | screens-landlord.js | EPIC-03 | T-013 | ☐ |
| 10 | `addTenant` | Add tenant (chooser) | Landlord | screens-landlord2.js | EPIC-04 | T-009 | ☐ |
| 11 | `ocr` | NID OCR scan | Landlord | screens-landlord2.js | EPIC-04 | T-010,T-011 | ☐ |
| 12 | `voice` | Voice fill | Landlord | screens-landlord2.js | EPIC-04 | T-012 | ☐ |
| 13 | `manualTenant` | Manual DMP form | Landlord | screens-landlord2.js | EPIC-04 | T-013 | ☐ |
| 14 | `dmp` | DMP form (review) | Landlord | screens-landlord2.js | EPIC-05 | T-007 | ☑ |
| 15 | `dmpPdf` | DMP PDF preview | Landlord | screens-landlord2.js | EPIC-05 | T-008 | ☑ |
| 16 | `rentReq` | Rent request | Landlord | screens-landlord2.js | EPIC-07 | T-011 | ☑ |
| 17 | `verifyPay` | Verify payment | Landlord | screens-landlord2.js | EPIC-07 | T-012 | ☑ |
| 18 | `receipt` | Receipt | Landlord | screens-landlord2.js | EPIC-07 | T-013 | ☑ |
| 19 | `expenses` | Maintenance & expenses | Landlord | screens-landlord2.js | EPIC-08 | T-008 | ☑ |
| 20 | `addExpense` | Add expense | Landlord | screens-landlord2.js | EPIC-08 | T-009 | ☑ |
| 21 | `dashboard` | Dashboard / charts | Landlord | screens-landlord2.js | EPIC-09 | T-006 | ☐ |
| 22 | `more` | More menu (profile, lang) | Landlord | screens-landlord2.js | EPIC-02 | T-007 | ☐ |
| 23 | `plan` | Plan & billing | Landlord | screens-landlord2.js | EPIC-10 | T-007 | ☐ |
| 24 | `verify` | NID verify | Landlord | screens-landlord2.js | EPIC-17 (P1) | T-006 | ☐ |
| 25 | `lease` | AI lease | Landlord | screens-landlord2.js | EPIC-18 (P1) | T-006 | ☐ |
| 26 | `warning` | Warning / complaint | Landlord | screens-landlord2.js | EPIC-20 (P1) | T-005 | ☐ |
| 27 | `mgrHome` | Manager home | Manager | screens-other.js | EPIC-22 (P1) | T-006 | ☐ |
| 28 | `mgrAddOwner` | Add owner | Manager | screens-other.js | EPIC-22 (P1) | T-007 | ☐ |
| 29 | `mgrTeam` | Team members | Manager | screens-other.js | EPIC-22 (P1) | T-008 | ☐ |
| 30 | `mgrReport` | Consolidated report | Manager | screens-other.js | EPIC-22 (P1) | T-009 | ☐ |
| 31 | `tenHome` | Tenant home | Tenant app | screens-other.js | EPIC-19 (P1) | T-005 | ☐ |
| 32 | `tenLease` | Lease detail | Tenant app | screens-other.js | EPIC-19 (P1) | T-006 | ☐ |
| 33 | `tenPay` | Pay rent | Tenant app | screens-other.js | EPIC-19 (P1) | T-007 | ☐ |
| 34 | `tenMaint` | Request maintenance | Tenant app | screens-other.js | EPIC-19 (P1) | T-008 | ☐ |
| 35 | `tenReceipts` | Receipts | Tenant app | screens-other.js | EPIC-19 (P1) | T-009 | ☐ |
| 36 | `tenReview` | Review landlord | Tenant app | screens-other.js | EPIC-21 (P1) | T-005 | ☐ |
| 37 | `tenRecord` | Good-tenant record | Tenant app | screens-other.js | EPIC-21 (P1) | T-010 | ☐ |
| 38 | `webPay` | Rent pay link | Web-link 🌐 | screens-other.js | EPIC-07 | T-005 | ☐ |
| 39 | `webReceipt` | Receipt view | Web-link 🌐 | screens-other.js | EPIC-07 | T-006 | ☐ |
| 40 | `webMaint` | Maintenance form | Web-link 🌐 | screens-other.js | EPIC-08 | T-005 | ☐ |
| 41 | `webVisitor` | Visitor QR form | Web-link 🌐 | screens-other.js | EPIC-25 (P2) | T-005 | ☐ |
| 42 | `careHome` | Caretaker home | Caretaker | screens-other.js | EPIC-25 (P2) | T-006 | ☐ |
| 43 | `careReview` | Visitor review | Caretaker | screens-other.js | EPIC-25 (P2) | T-007 | ☐ |
| 44 | `careLog` | Visitor log | Caretaker | screens-other.js | EPIC-25 (P2) | T-008 | ☐ |

**Legend:** `Task` = `_TBD_` means the owning epic isn't written yet; it will be filled with the real `T-XXX` when that epic is authored. `Built?` ☐→☑ when the task is `verified`.

### Coverage by epic (every screen has a home)
- **EPIC-01** (4): splash, intro, login, otp ✅ *tasks exist*
- **EPIC-02** (2): roleChooser, more
- **EPIC-03** (4): home, addBuilding, portfolio, unit
- **EPIC-04** (4): addTenant, ocr, voice, manualTenant
- **EPIC-05** (2): dmp, dmpPdf
- **EPIC-07** (5): rentReq, verifyPay, receipt, webPay, webReceipt
- **EPIC-08** (3): expenses, addExpense, webMaint
- **EPIC-09** (1): dashboard
- **EPIC-10** (1): plan
- **EPIC-17 P1** (1): verify
- **EPIC-18 P1** (1): lease
- **EPIC-19 P1** (5): tenHome, tenLease, tenPay, tenMaint, tenReceipts
- **EPIC-20 P1** (1): warning
- **EPIC-21 P1** (2): tenReview, tenRecord
- **EPIC-22 P1** (4): mgrHome, mgrAddOwner, mgrTeam, mgrReport
- **EPIC-25 P2** (4): webVisitor, careHome, careReview, careLog

**Sum check:** 4+2+4+4+2+5+3+1+1+1+1+5+1+2+4+4 = **44 ✅** — every prototype screen is assigned to exactly one owning epic.

### Shared UI primitives (not screens — built once in EPIC-00 T-008, reused everywhere)
From `proto/ui.js`: `statusbar`, `topbar`, `bottomnav`, `emojiHero`, `iconBadge`, `field`, `avatar`, `bellbtn`, plus the CSS classes `k-btn`, `k-card`, `k-chip`, `k-field`, `k-track`. These map to Flutter `lib/core/widgets/` and must exist before screen tasks consume them.

### How the gate is enforced
1. **When I write an epic:** I create a task for every screen the ledger assigns to it, and fill that screen's `Task` cell with the real `T-XXX`. The epic's `_epic.md` acceptance criteria explicitly lists its screens.
2. **When an agent finishes an epic:** the completion report must confirm every ledger screen for that epic is `built? ☑`. Any `_TBD_` or unbuilt screen blocks epic closure.
3. **Periodic audit:** `infra/scripts/tracker.py` can cross-check this ledger against existing task files and flag any screen whose task doesn't exist or isn't done (a `make screen-coverage` check — added to T-012 scope).
