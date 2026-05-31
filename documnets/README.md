# Khatir — Complete Current Bundle

**This single ZIP contains everything written so far, fully up to date.** Extract at your repo root; the `docs/` folder drops straight into place.

Last updated: this delivery includes EPIC-00, EPIC-01, EPIC-02 (all final), plus all architecture, design, and product docs.

---

## What's inside

```
docs/
├── product/                        WHAT to build (business + requirements)
│   ├── 01_BRD_Khatir.md
│   ├── 02_SRS_Khatir.md
│   ├── 03_Backlog_and_Flows_Khatir.md
│   └── 04_Admin_Portal_Khatir.md
│
├── architecture/                   HOW it's structured (engineering rules)
│   ├── 00_overview.md
│   ├── 01_stack_and_standards.md   (latest-stable policy)
│   ├── 02_project_structure.md
│   ├── 03_env_and_config.md
│   ├── 04_coding_conventions.md
│   ├── 05_navigation_routing.md    (4-step add-building wizard)
│   ├── 06_database_schema.md       (human-readable, 9 domains)
│   ├── 07_design_map.md            (screen→task map + 44-screen coverage ledger)
│   └── enums.md
│
├── design/
│   └── khatir-ui/                  The Khatir prototype (source of truth for UI)
│       ├── README.md
│       ├── Khatir Mobile Prototype.html
│       ├── proto/*.js              (all 44 screens)
│       ├── proto.css, ui.js, styles/, assets/
│
└── epics/
    ├── README.md                   Master tracker (26 epics)
    ├── _master_plan.md             All 26 epics + dependencies
    ├── _task_template.md           Strict task template (design anchor + lane + checklist convention)
    ├── _handoff_protocol.md        Agent handoff + peer review + §3b checklist-execution rules
    ├── _glossary.md
    ├── EPIC-00-foundation/         ✅ 16 tasks — FINAL
    ├── EPIC-01-onboarding-auth/    ✅ 12 tasks — FINAL
    └── EPIC-02-role-profile/       ✅ 8 tasks — FINAL
```

---

## Build progress

| Stage | Status |
|-------|--------|
| Product specs (BRD/SRS/Backlog/Admin) | ✅ |
| Architecture & standards (8 docs + enums) | ✅ |
| Design map + 44-screen coverage ledger | ✅ |
| Design prototype (in-repo) | ✅ |
| Master epic plan (all 26) | ✅ |
| **EPIC-00** Foundation (16 tasks) | ✅ FINAL |
| **EPIC-01** Onboarding & Auth (12 tasks) | ✅ FINAL |
| **EPIC-02** Role & Profile (8 tasks) | ✅ FINAL |
| EPIC-03 → EPIC-26 (23 epics, ~246 tasks) | ⏳ pending |

**36 of ~282 tasks specced across 3 of 26 epics.**

---

## How to start building

1. Open Claude Code at your repo root.
2. Tell it to read `docs/architecture/00_overview.md` → `01`–`07` + `enums.md`, then `docs/epics/_handoff_protocol.md` + `_task_template.md`.
3. Execute `docs/epics/EPIC-00-foundation/T-001-monorepo-structure.md` first (it has no dependencies), then walk forward with `make next`.

The design prototype is in `docs/design/khatir-ui/` — any CLI can read it; UI tasks point at exact screens via `docs/architecture/07_design_map.md`.
