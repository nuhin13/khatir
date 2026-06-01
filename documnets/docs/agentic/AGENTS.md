# AGENTS.md — Khatir Agent Operating Rules (canonical, platform-agnostic)

> This is the ONE rules file. `sync-agent-rules.sh` copies it to every platform's
> expected name (`CLAUDE.md`, `GEMINI.md`, `.cursor/rules/khatir.md`, …). Edit here only.
> Generic core + thin platform shims. Everything that matters is in this file.

You are a software engineering agent building **Khatir** (খাতির), a Dhaka landlord-compliance
SaaS. You work by executing pre-written task specs. You do not invent scope.

---

## 0. The contract (read this first, every session)

For any task assigned to you (`docs/epics/EPIC-NN/T-XXX.md`):

1. **Read the task fully** — all 15 sections — before writing any code.
2. **Implement exactly §3 ("What this task DOES").** Do **not** do anything in §4 ("does NOT do").
3. **Honor the design anchor in §8.** If a screen names `reg('screenKey')`, open that screen in
   `docs/design/khatir-ui/proto/*.js` and match its layout + copy. Design is source of truth.
4. **Check off §11 as you go.** Flip `- [ ]` → `- [x]` the moment an item is truly done, and
   append the short git hash: `` - [x] models created `a1b2c3d` ``. Never hand off with `(uncommitted)`.
5. **Run `make test && make lint`** (or the layer equivalent). Green before done.
6. **Fill §14 self-review** — the deviations list and files-touched list, honestly.
7. **Commit** with a message referencing the task id: `EPIC-04/T-007: tenant CRUD + for_user`.
8. **Update the epic `_checklist.md`** row for this task.
9. **Stop and report.** Do not silently start the next task. One task → review → next.

If you ever feel you must deviate from the spec, **stop and ask** instead of guessing.

---

## 1. Orientation (do once per repo, at the start)

Read, in order: `docs/architecture/00_overview.md` → `01_stack_and_standards.md` →
`02_project_structure.md` → `03_env_and_config.md` → `04_coding_conventions.md` →
`05_navigation_routing.md` → `06_database_schema.md` → `07_design_map.md` → `enums.md`.
Then `docs/epics/_handoff_protocol.md` + `_task_template.md` + `_master_plan.md`.

Find your next task with `make next` (or `make next LAYER=backend|mobile|admin|infra`).

---

## 2. Non-negotiable engineering rules (from 04_coding_conventions.md)

- **Always latest stable** versions (floor: Python 3.13, Django 6.0.x, DRF 3.17, Flutter 3.44,
  Next.js 16.2, React 19, Node 22 LTS, PG 17, Redis 8). Never pin to old majors.
- **Money is `Decimal(12,2)`.** Never float for currency.
- **Datetimes are UTC** in storage.
- **Enums everywhere** — use the values in `enums.md`, never magic strings.
- **Config lives in the DB** (SystemConfig / PricingTier / FeatureFlag / AIProvider). Never hardcode
  a price, limit, area list, template version, or provider key.
- **`for_user` row isolation** on every read of user-owned data. Cross-user access returns 404, not 403.
- **NID is encrypted at rest + masked in display.** Never log it, never return the full value except
  via the explicit audited decrypt path. Store the *result*, never the raw provider payload.
- **Audit** every personal-data write and every admin write.
- **Bangla-default i18n** — every user string in ARB (bn + en). Lift copy from the prototype.
- **Every screen has loading / error / empty / data states.** No screen ships with only the happy path.
- **Design tokens, not hardcoded styles.** Use `packages/design-tokens`; never paste a prototype hex.
- **Reuse, don't duplicate.** PDF infra → reuse EPIC-05's. Tokens/links → reuse EPIC-07's. Notifications
  → reuse EPIC-01's `NotificationSender`. Encryption/storage → reuse `core` helpers.

## 2a. Legal-safety invariants (hard, non-negotiable)

- **Never build a public, searchable, or cross-party reputation/blacklist feature.** Warnings, reviews,
  and history are **private, consent-gated, kill-switchable** by construction. If a task seems to ask
  for a public reputation lookup, STOP — that's illegal under the Cyber Security Ordinance 2025.
- **Reputation-adjacent features check their kill-switch first** (`warnings_feature`, `reviews_feature`,
  `history_flags_feature`) and return `feature_disabled` when off.
- **NID verification returns only Matched / Not Matched / Error.** Never raw EC data. Never "Porichoy" branding.
- **Consent before any data sharing.** Record a `ConsentRecord`. Default deny.

## 2b. Wellbeing / safety
You do not need access to secrets to do tasks; never print API keys, tokens, or NID values to logs
or commit them. `.env` is never committed.

---

## 3. Definition of done (a task is NOT done until all are true)

- [ ] §3 implemented; §4 respected (nothing extra built).
- [ ] §8 design anchor matched (if UI).
- [ ] `make test` passes; `make lint` clean.
- [ ] §11 checklist fully checked with git hashes.
- [ ] §13 acceptance criteria genuinely met.
- [ ] §14 self-review filled (deviations + files touched).
- [ ] Committed; `_checklist.md` updated; frontmatter `status` advanced.
- [ ] You stopped and reported (did not auto-start the next task).

---

## 4. Reviewing (when you are the peer reviewer, not the implementer)

When asked to review a task's branch/diff:
1. Read the task's §3, §4, §8, §13.
2. Check the diff *against those* — not against your own idea of the feature.
3. Verify tests + lint actually ran (not just claimed).
4. Write a verdict to `docs/agentic/results/reviews/<task>.md`: **PASS** / **CHANGES NEEDED** + a
   short bullet list of concrete issues mapped to acceptance criteria. Be specific, not vague.
5. Do **not** rewrite the code yourself; report so the human merges or sends back.

---

## 5. Commit & branch protocol

- Branch per task: `epic-NN/t-XXX-short-name`.
- Small, frequent commits; the §11 checklist hashes should point at real commits.
- Commit message: `EPIC-NN/T-XXX: <what>`. Reference acceptance criteria in the body if useful.
- Never force-push shared branches. Never commit secrets, `.env`, build artifacts, or `node_modules`.

---

## 6. When stuck

- Missing context the task assumes exists? Search the repo first (`make next` deps, the referenced
  prior-epic tasks). Don't re-implement something a dependency already built.
- Genuinely blocked (missing upstream task, ambiguous spec, external creds absent)? Set the task
  `status: blocked`, note why in §15, and report. Do not guess past a hard gate (e.g. EPIC-05 T-010
  needs the real DMP form — a human provides it).

---

## 7. Platform shim (the ONLY platform-specific section)

Everything above is generic. Per-platform tool access / MCP config goes in
`docs/agentic/shims/<platform>.md` and is appended by `sync-agent-rules.sh`. Keep the generic
contract identical across platforms — only tool wiring differs.
