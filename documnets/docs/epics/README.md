# Khatir · Epic Tracker

> The live dashboard. Agents update this on every status change. `make status` regenerates the counts from task-file frontmatter.

**Last updated:** (init)

---

## How to use this directory

- **Read order for a new agent/session:**
  1. `../architecture/00_overview.md` → the system map
  2. `../architecture/01_…` through `06_…` → the rules
  3. `_master_plan.md` → all epics + dependencies
  4. This file → what's done / what's next
  5. The specific `EPIC-NN-…/_epic.md` you're working on
  6. The specific `T-XXX-….md` task

- **To find the next task:** `make next` (returns lowest-ID `todo` task with all deps met).
- **To see review queue:** `make review-queue`.
- **To close an epic:** all tasks `verified` → `make epic-report NN` → human sign-off.

- **Task lifecycle & handoff:** see `_task_template.md` and `_handoff_protocol.md`.

---

## Overall progress

| Metric | Count |
|--------|-------|
| Epics total | 26 |
| Epics done | 0 |
| Epics in-progress | 0 |
| Tasks total | ~260 (finalized per epic as written) |
| Tasks done | 0 |
| Tasks in-progress | 0 |
| Tasks blocked | 0 |

---

## Epic status board

Legend: ⬜ todo · 🟡 in-progress · ✅ done · ⛔ blocked

### Foundation
| ID | Epic | Phase | Tasks | Status | Progress |
|----|------|-------|-------|--------|----------|
| EPIC-00 | Foundation & Scaffold | — | 16 | ⬜ | 0/16 |

### MVP
| ID | Epic | Phase | Tasks | Status | Progress |
|----|------|-------|-------|--------|----------|
| EPIC-01 | Onboarding & Authentication | MVP | 12 | ⬜ | 0/12 |
| EPIC-02 | Role & Profile Management | MVP | 8 | ⬜ | 0/8 |
| EPIC-03 | Properties & Units | MVP | TBD | ⬜ | 0/0 |
| EPIC-04 | Tenant Management & NID OCR | MVP | TBD | ⬜ | 0/0 |
| EPIC-05 | DMP Form Generation ★ | MVP | TBD | ⬜ | 0/0 |
| EPIC-06 | Lease & Rent Schedule | MVP | TBD | ⬜ | 0/0 |
| EPIC-07 | Rent Collection (Web-Link) | MVP | TBD | ⬜ | 0/0 |
| EPIC-08 | Maintenance & Expense Tracker | MVP | TBD | ⬜ | 0/0 |
| EPIC-09 | Dashboard & Visualizations | MVP | TBD | ⬜ | 0/0 |
| EPIC-10 | Pricing Tiers & Free Limit | MVP | TBD | ⬜ | 0/0 |
| EPIC-11 | Admin Portal Foundation | MVP | TBD | ⬜ | 0/0 |
| EPIC-12 | Admin · Pricing & Users | MVP | TBD | ⬜ | 0/0 |
| EPIC-13 | Admin · Feature Flags & Kill-switch | MVP | TBD | ⬜ | 0/0 |
| EPIC-14 | Admin · AI Providers | MVP | TBD | ⬜ | 0/0 |
| EPIC-15 | Admin · Notifications | MVP | TBD | ⬜ | 0/0 |
| EPIC-16 | Admin · Audit & Compliance | MVP | TBD | ⬜ | 0/0 |

### Phase 1
| ID | Epic | Phase | Tasks | Status | Progress |
|----|------|-------|-------|--------|----------|
| EPIC-17 | NID Verification (EC API) | P1 | TBD | ⬜ | 0/0 |
| EPIC-18 | AI Lease Generation | P1 | TBD | ⬜ | 0/0 |
| EPIC-19 | Tenant App Features | P1 | TBD | ⬜ | 0/0 |
| EPIC-20 | Private Warnings | P1 | TBD | ⬜ | 0/0 |
| EPIC-21 | Mutual Reviews | P1 | TBD | ⬜ | 0/0 |
| EPIC-22 | B2B Manager Tier | P1 | TBD | ⬜ | 0/0 |
| EPIC-23 | AI Support Chatbot | P1 | TBD | ⬜ | 0/0 |

### Phase 2
| ID | Epic | Phase | Tasks | Status | Progress |
|----|------|-------|-------|--------|----------|
| EPIC-24 | History Flags | P2 | TBD | ⬜ | 0/0 |
| EPIC-25 | Gatekeeper / Caretaker | P2 | TBD | ⬜ | 0/0 |

### Phase 3
| ID | Epic | Phase | Tasks | Status | Progress |
|----|------|-------|-------|--------|----------|
| EPIC-26 | Government Export | P3 | TBD | ⬜ | 0/0 |

---

## Review queue
(empty)

## Recently completed
(none yet)

## Currently blocked
(none)
