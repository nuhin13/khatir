# Task File Template

> Every task file (`T-XXX-slug.md`) uses this exact structure. Copy this template. The YAML frontmatter is machine-readable — agents parse it to find the next task and update status. The body is the complete spec an agent needs to execute with zero outside context beyond the architecture docs.

---

## The template

````markdown
---
id: T-XXX
epic: EPIC-NN
title: Short imperative title
layer: backend            # backend | mobile | admin | infra | docs | cross-cutting
size: S                   # XS (~2h) | S (~1d) | M (~2-3d) | L (~1wk)
status: todo              # todo | in-progress | blocked | review-requested | changes-requested | done | verified
preferred_agent: claude-code   # claude-code | codex | any
depends_on: []            # e.g. [EPIC-00.T-003, T-002]  (same-epic refs need no prefix)
blocks: []
external_services: []     # e.g. [cloud-vision, twilio]
feature_flags: []         # flags this task introduces or toggles
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-XXX · {Title}

## 1. Feature goal
One sentence. What this task achieves for the product/user.

## 2. Business logic
The rules. What must be true, what's forbidden, edge cases. Reference the SRS FR numbers
(e.g. "implements FR-4.2"). Be explicit about Bangladesh-specific or legal constraints.

## 3. What this task DOES
- Concrete deliverable 1
- Concrete deliverable 2

## 4. What this task does NOT do
- Explicit non-goal (deferred to T-YYY)
- Prevents scope creep

## 5. Files & changes

### Add
- `path/to/file` — purpose

### Update
- `path/to/file` — what changes and why

### Delete
- (usually none)

## 6. Database changes
- Migration: `NNNN_description`
- Tables/columns added or changed
- Indexes
- Reversible? Data backfill?
- (If none: "No DB changes.")

## 7. API changes
| Method | Path | Auth | Request | Response | Status |
|--------|------|------|---------|----------|--------|
| POST | /api/v1/... | Bearer landlord | {...} | {...} | 201 |
(If none: "No API changes.")

## 8. UI changes
> For mobile/admin tasks, name the exact design screen. See `docs/architecture/07_design_map.md`.
- **Design source:** screen `<screenKey>` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/<file>.js` → `reg('<screenKey>')`)
- Surface: mobile | admin   ·   **Lane:** 🟢 mobile / 🟣 admin / 🌐 web-link
- Screen / route: reference `05_navigation_routing.md`
- Translate layout + composition + copy; **values (color/spacing/radii) from `packages/design-tokens`**, never copied from the prototype's inline styles
- States required: loading / error / empty / data
- Navigation: from → to
- i18n keys added (bn + en) — lift Bangla/English copy from the prototype screen
(If none: "No UI changes.")

## 9. External services
- Service, env vars needed, failure behavior
(If none: "None.")

## 10. Feature flags
- key · default · scope
(If none: "None.")

## 11. Implementation checklist
> Live execution log — check items off **as you complete them** and append the short commit hash, e.g. `- [x] Model(s) + enums  ` + "`a1b2c3d`". Multiple items may share one commit; one item may list multiple hashes. See `_handoff_protocol.md` §3b for the full convention.

Tailor to the layer. Example (backend):
- [ ] Model(s) + enums
- [ ] Migration (reversible)
- [ ] Manager `for_user` scope
- [ ] Serializer(s)
- [ ] Service function(s) — logic here, not in view
- [ ] Permission class(es)
- [ ] View(s)/viewset thin
- [ ] URL wiring under /api/v1
- [ ] Audit on personal-data writes
- [ ] Tests: happy + auth-fail + validation-fail
- [ ] API doc updated
- [ ] DECISIONS.md note if a tradeoff was made

Example (mobile):
- [ ] freezed model(s) matching wire schema
- [ ] Repository method (dio)
- [ ] Riverpod provider/controller
- [ ] Screen with loading/error/empty/data
- [ ] Route in app_router.dart
- [ ] i18n strings bn + en
- [ ] Theme tokens used (no inline colors/strings)
- [ ] Widget test for primary screen

## 12. Test plan
### Automated
- test_name → asserts what
### Manual QA (human/agent runs these)
1. Step
2. Step
3. Expected result

## 13. Acceptance criteria
- [ ] Observable condition 1 (user can X)
- [ ] System persists/audits Y
- [ ] make test && make lint pass for affected app

## 14. Self-review (agent fills BEFORE setting status=review-requested)
- [ ] All checklist items done
- [ ] make test passes
- [ ] make lint passes
- [ ] Loading/error/empty states present (if UI)
- [ ] i18n complete (if UI)
- [ ] Audit present (if personal data)
- [ ] No secrets/PII logged

### Deviations from spec
(none, or list)

### Files touched (actual)
- ...

## 15. Notes for the implementing agent
- Gotchas, exact Bangla strings to use, links to JSX prototype, anything subtle.

## 16. Handoff (only if status=blocked — see _handoff_protocol.md)
- What was tried
- Why blocked
- What's needed to unblock
- Suggested next agent/task
````

---

## Field rules

- **`id`** unique within the epic. Cross-epic reference uses `EPIC-NN.T-XXX`.
- **`depends_on`** must be satisfied (`done` or `verified`) before an agent may start this task. The `make next` script enforces this.
- **`size`** guides batching; not a deadline.
- **`status`** transitions: `todo → in-progress → review-requested → done → verified`. Side paths: `→ blocked` (with §16 filled), `review-requested → changes-requested → in-progress`.
- **`layer`** is the lane: `backend` 🔵 / `mobile` 🟢 / `admin` 🟣 / `infra` ⚙️ / `docs` 📄 / `cross-cutting` 🔶. An agent stream can pull only its lane via `make next LAYER=<layer>`. Cross-layer dependencies still gate correctly (a mobile task depending on a backend task won't be "ready" until the backend one is done/verified).
- **`preferred_agent`** is a hint, not a lock. Any capable agent may execute. Architecture/multi-file/ambiguous → claude-code. Mechanical/per-file boilerplate → codex.

## How an autonomous agent uses a task file
1. `make next` → returns lowest-ID `todo` task whose `depends_on` are all `done`/`verified`.
2. Read the task file fully + the architecture docs it references.
3. Set `status: in-progress`, `started_at`, `executed_by`. Commit branch `epic-NN/T-XXX-slug`.
4. Implement per §11. Keep to §3/§4 scope.
5. Run `make test && make lint`. Fill §14 self-review.
6. If stuck → set `status: blocked`, fill §16, push. Loop picks next unblocked task.
7. If done → `status: review-requested`, `completed_at`. Open PR. Update `_checklist.md`.
8. Reviewer (peer AI then human) sets `done`/`changes-requested`.
