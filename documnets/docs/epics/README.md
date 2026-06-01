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
| Epics in-progress | 1 |
| Tasks total | 302 (all epics fully specced) |
| Tasks done | 8 |
| Tasks in-progress | 0 |
| Tasks blocked | 0 |

---

## Epic status board

Legend: ⬜ todo · 🟡 in-progress · ✅ done · ⛔ blocked

### Foundation
| ID | Epic | Phase | Tasks | Status | Progress |
|----|------|-------|-------|--------|----------|
| EPIC-00 | Foundation & Scaffold | — | 16 | 🟡 | 8/16 |

### MVP
| ID | Epic | Phase | Tasks | Status | Progress |
|----|------|-------|-------|--------|----------|
| EPIC-01 | Onboarding & Authentication | MVP | 12 | ⬜ | 0/12 |
| EPIC-02 | Role & Profile Management | MVP | 8 | ⬜ | 0/8 |
| EPIC-03 | Properties & Units | MVP | 14 | ⬜ | 0/14 |
| EPIC-04 | Tenant Management & NID OCR | MVP | 16 | ⬜ | 0/16 |
| EPIC-05 | DMP Form Generation ★ | MVP | 10 | ⬜ | 0/10 |
| EPIC-06 | Lease & Rent Schedule | MVP | 10 | ⬜ | 0/10 |
| EPIC-07 | Rent Collection (Web-Link) ★ | MVP | 14 | ⬜ | 0/14 |
| EPIC-08 | Maintenance & Expense Tracker | MVP | 12 | ⬜ | 0/12 |
| EPIC-09 | Dashboard & Visualizations | MVP | 10 | ⬜ | 0/10 |
| EPIC-10 | Pricing Tiers & Free Limit | MVP | 9 | ⬜ | 0/9 |
| EPIC-11 | Admin Portal Foundation | MVP | 12 | ⬜ | 0/12 |
| EPIC-12 | Admin · Pricing & Users | MVP | 10 | ⬜ | 0/10 |
| EPIC-13 | Admin · Feature Flags & Kill-switch | MVP | 8 | ⬜ | 0/8 |
| EPIC-14 | Admin · AI Providers | MVP | 12 | ⬜ | 0/12 |
| EPIC-15 | Admin · Notifications | MVP | 14 | ⬜ | 0/14 |
| EPIC-16 | Admin · Audit & Compliance | MVP | 9 | ⬜ | 0/9 |

### Phase 1
| ID | Epic | Phase | Tasks | Status | Progress |
|----|------|-------|-------|--------|----------|
| EPIC-17 | NID Verification (EC API) | P1 | 10 | ⬜ | 0/10 |
| EPIC-18 | AI Lease Generation | P1 | 10 | ⬜ | 0/10 |
| EPIC-19 | Tenant App Features | P1 | 14 | ⬜ | 0/14 |
| EPIC-20 | Private Warnings | P1 | 10 | ⬜ | 0/10 |
| EPIC-21 | Mutual Reviews | P1 | 10 | ⬜ | 0/10 |
| EPIC-22 | B2B Manager Tier | P1 | 12 | ⬜ | 0/12 |
| EPIC-23 | AI Support Chatbot | P1 | 8 | ⬜ | 0/8 |

### Phase 2
| ID | Epic | Phase | Tasks | Status | Progress |
|----|------|-------|-------|--------|----------|
| EPIC-24 | History Flags | P2 | 12 | ⬜ | 0/12 |
| EPIC-25 | Gatekeeper / Caretaker | P2 | 14 | ⬜ | 0/14 |

### Phase 3
| ID | Epic | Phase | Tasks | Status | Progress |
|----|------|-------|-------|--------|----------|
| EPIC-26 | Government Export | P3 | 6 | ⬜ | 0/6 |

---

## Review queue
(empty)

## Recently completed
(none yet)

## Currently blocked
(none)
