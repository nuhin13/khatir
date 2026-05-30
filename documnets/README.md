# Khatir — Complete Project Bundle

**This ZIP always contains everything, current as of the latest update.** Nothing is kept loose outside the ZIP, so there's never a broken or stale download.

---

## What's inside

```
Khatir-Complete/
├── README.md                          ← This file (the index)
│
├── docs/
│   ├── product/                       WHAT to build (business + requirements)
│   │   ├── 01_BRD_Khatir.md           Business Requirements
│   │   ├── 02_SRS_Khatir.md           Software Requirements
│   │   ├── 03_Backlog_and_Flows_Khatir.md
│   │   └── 04_Admin_Portal_Khatir.md
│   │
│   ├── architecture/                  HOW it's structured (engineering rules)
│   │   ├── 00_overview.md             System map — read first
│   │   ├── 01_stack_and_standards.md  Versions, coding standards, git rules
│   │   ├── 02_project_structure.md    Mono-repo layout
│   │   ├── 03_env_and_config.md       Env vars, config layers
│   │   ├── 04_coding_conventions.md   API envelope, multi-tenancy, naming
│   │   ├── 05_navigation_routing.md   Flutter + Next.js routing
│   │   ├── 06_database_schema.md      Full ERD + tables
│   │   └── enums.md                   Canonical enums (all surfaces match)
│   │
│   └── epics/                         The work plan + tracking
│       ├── README.md                  Master tracker dashboard (26 epics)
│       ├── _task_template.md          Strict task file template
│       ├── _handoff_protocol.md       Agent-to-agent handoff + review chain
│       └── _glossary.md               Shared vocabulary
│
├── ui/                                React reference UIs (visual contracts)
│   ├── KhatirMobile.jsx               Mobile app (all roles + screens)
│   └── KhatirAdmin.jsx                Admin portal
│
└── logos/                             Brand asset pack
    ├── build_pngs.py                  Regenerate PNGs from SVG
    ├── *.svg                          9 source files
    ├── *.png                          23 raster exports
    └── favicon.ico
```

---

## Build progress

| Stage | What | Status |
|-------|------|--------|
| Product specs | BRD, SRS, Backlog, Admin spec | ✅ Done |
| Brand | Logo (খ monogram) + full asset pack | ✅ Done |
| UI references | Mobile + Admin JSX | ✅ Done |
| **Step 1** | Architecture & standards (8 arch docs + 4 epic-system docs) | ✅ Done |
| **Step 2** | Master Epic Plan (all 26 epics, dependencies) | ⏳ Next |
| **Step 3** | EPIC-00 Foundation — full task files | ⏳ Pending |
| Steps 4+ | Each remaining epic, fully task-specced | ⏳ Pending |

---

## How to read this (for a new agent or session)

1. `docs/architecture/00_overview.md` — the system map
2. `docs/architecture/01` → `06` + `enums.md` — the rules
3. `docs/epics/README.md` — what's done / next
4. `docs/epics/_master_plan.md` — all epics (arrives in Step 2)
5. The specific `EPIC-NN/_epic.md` + `T-XXX.md` you're executing (arrives Step 3+)

## Locked decisions

- **Backend:** Django 5.1 + DRF monolith (AI gateway as FastAPI microservice in EPIC-14)
- **Mobile:** One Flutter app, role-based shells (landlord/manager/tenant)
- **Admin:** Next.js 15 (App Router)
- **Repo:** Single mono-repo (`apps/api`, `apps/mobile`, `apps/admin`, `services/`, `infra/`, `docs/`)
- **Brand:** Khatir · খ monogram on sage tile · Notun Din palette
- **Execution:** autonomous task loop, peer AI review, human final sign-off
