# Agent Handoff Protocol

> How work moves between agents (Claude Code, Codex, OpenCode, OpenRouter models) and between agent and human. The system must survive any single agent getting stuck, and must let a different CLI pick up cleanly.

---

## 1. Core principle

**No agent is special.** A task file + the architecture docs contain everything needed to execute. Any agent that can read markdown and write code can pick up any `todo` task whose dependencies are met. Handoffs happen through the task file and git, never through agent memory or chat history.

---

## 2. The review chain (recap)

```
Agent implements
   → Agent self-review (§14 of task)
      → status: review-requested
         → Peer AI review (a DIFFERENT agent than the implementer)
            → status: done  OR  changes-requested
               → Human approval
                  → status: verified
```

- **Implementer ≠ peer reviewer.** If Codex implemented, Claude Code (or another model) reviews, and vice-versa. This catches single-model blind spots.
- The human is the final gate but reviews the *peer-approved* result, so their time is spent on judgment, not catching typos.

---

## 3. When to hand off

An agent hands off in three situations:

### A. Blocked (can't finish)
Set `status: blocked`, fill §16 of the task:
```markdown
## 16. Handoff
- **What was tried:** wired Cloud Vision OCR, extraction returns empty for Bangla NID back-side.
- **Why blocked:** need the actual DMP form field mapping; the official template isn't in the repo.
- **What's needed to unblock:** human to provide official DMP form PDF, OR decision to use a placeholder layout for now.
- **Suggested next:** human input required. Meanwhile T-009 (manual entry path) is unblocked and can proceed.
```
Commit and push. The loop moves to the next unblocked task. A human or another agent resolves the blocker later.

### B. Cross-domain (task needs a skill the current agent is weak at)
Example: Codex did the Django model/serializer cleanly but the task also needs a tricky Flutter animation. Codex sets `status: in-progress`, appends:
```markdown
## 16. Handoff (partial)
- **Done:** backend portion complete and tested (commit abc123).
- **Remaining:** Flutter screen with the camera overlay animation.
- **Why handing off:** UI animation work — better suited to claude-code.
- **Suggested next agent:** claude-code, continue same branch epic-04/T-007.
```
Pushes the branch. Next agent continues the *same branch/task*, not a new one.

### C. Review handoff (always cross-agent)
On `review-requested`, the peer reviewer is by definition a different agent. The reviewer reads the diff + self-review, runs `make test && make lint`, and either approves (`done`) or requests changes with a concrete list:
```markdown
## Review notes (peer: claude-code, 2026-06-02)
- ❌ `for_user` scope missing on TenantQuerySet — security gap, must fix.
- ❌ money stored as FloatField — must be Decimal(12,2).
- ⚠️ no empty-state on the list screen.
- ✅ tests good, i18n complete.
Outcome: changes-requested.
```
Implementer reads notes, fixes, re-submits.

---

## 3b. Executing the implementation checklist (live progress + git refs)

The `## 11. Implementation checklist` in every task file is not a static plan — it's a **live execution log** the agent updates *as it works*, so the task file itself becomes the audit trail.

**Rules:**

1. **Check off as you go.** The moment a checklist item is genuinely complete (code written *and* locally working), change `- [ ]` to `- [x]`. Don't batch-check at the end — check each item when it's actually done. This lets a reviewer or a resuming agent see exactly how far the task got.

2. **Annotate with the commit reference.** When you commit work that completes one or more checklist items, append the short commit hash to those items:
   ```
   - [x] Model(s) + enums  `a1b2c3d`
   - [x] Migration (reversible)  `a1b2c3d`
   - [x] Serializer(s)  `e4f5g6h`
   ```
   - **Multiple items can share one commit** — that's expected and fine. Just put the same hash on each item that commit covered:
     ```
     - [x] Service function(s)  `e4f5g6h`
     - [x] Permission class(es)  `e4f5g6h`
     ```
   - **One item may span multiple commits** — list both:
     ```
     - [x] View(s)/viewset  `e4f5g6h, i7j8k9l`
     ```
   - If work isn't committed yet but the item is done locally, mark `- [x]` and add `(uncommitted)`; replace with the hash on the next commit. Never hand off with `(uncommitted)` still present — see §4.

3. **Hash format.** Use the 7-char short hash. The full branch is already `epic-NN/T-XXX-slug`, and every commit message carries `[EPIC-NN T-XXX]`, so the task ID → commits mapping is recoverable from git history too; the inline hash is a convenience for human reviewers reading the task file.

4. **Partial completion is legible.** If a task is handed off or blocked midway, the checklist already shows which items are `[x]` (with hashes) and which remain `[ ]`. The next agent continues from the first unchecked item on the same branch.

5. **The self-review (§14) "Files touched (actual)" still lists the concrete files** — the checklist tracks *what was done*, the self-review confirms *it's done correctly*. Both are required.

**Example of a checklist mid-execution:**
```markdown
## 11. Implementation checklist
- [x] Model(s) + enums  `a1b2c3d`
- [x] Migration (reversible)  `a1b2c3d`
- [x] Manager `for_user` scope  `a1b2c3d`
- [x] Serializer(s)  `e4f5g6h`
- [x] Service function(s) — logic here, not in view  `e4f5g6h`
- [ ] Permission class(es)
- [ ] View(s)/viewset thin
- [ ] Tests: happy + auth-fail + validation-fail
```
A reviewer instantly sees: models/migration/serializer/service done across two commits; permissions, views, tests still pending.

---

## 4. Handoff hygiene (rules)

1. **Always leave the repo green or clearly red.** Either `make test` passes, or §16 explains exactly what's failing and why.
2. **Commit before handing off.** Uncommitted work is invisible to the next agent.
3. **Same task = same branch.** Continue partial work on the existing branch; don't fork.
4. **Write for a stranger.** Assume the next agent has zero memory of your session. Spell out file paths, commit hashes, decisions.
5. **Update `_checklist.md`** with the status change and who did what.
6. **Never silently change scope.** If you discover the task needs more, note it in §4/§16 and, if large, propose a new task rather than ballooning this one.
7. **Decisions go in `DECISIONS.md`.** Any non-obvious choice (library pick, pattern, tradeoff) gets one line with date + rationale, so future agents don't re-litigate it.

---

## 5. Conflict & ambiguity resolution

- **Spec ambiguity:** if the task + SRS + architecture docs don't resolve a question, the agent picks the simplest interpretation that satisfies the acceptance criteria, notes the assumption in §15, and flags it for human review. Don't stall on small ambiguities.
- **Spec contradiction:** if two docs conflict, `docs/product/` (SRS) wins on *what*, `docs/architecture/` wins on *how*. If still unclear → `status: blocked`, human decides.
- **Two agents touch the same files:** the dependency graph (`depends_on`/`blocks`) is designed to prevent this. If it happens, the later agent rebases on the earlier merged work; never force-push over another agent's commits.

---

## 6. What the human is for

The human (you) is pulled in only when:
- A task is `blocked` needing a decision or external input (official forms, API access, legal opinion).
- Final `verified` sign-off after peer AI approval.
- An epic completion report needs sign-off.
- A `DECISIONS.md`-level architectural choice arises that changes multiple epics.

Everything else runs agent-to-agent.

---

## 7. CLI-agnostic execution (the longer-term goal)

Task files deliberately avoid any CLI-specific syntax. The same task is executable by:
- **Claude Code** — best for architecture, multi-file, ambiguity, review.
- **Codex** — best for per-file boilerplate, mechanical tasks.
- **OpenCode / OpenRouter models** — fallback / parallelism.

A thin runner script (built post-MVP, see note) can:
1. `make next` → pick task.
2. Route to preferred agent (or any available).
3. Feed the agent: the task file + referenced architecture docs.
4. On completion, route to a *different* agent for peer review.
5. Update status, open PR, surface review-queue to human.

**The "agents & skills" layer you mentioned is intentionally deferred** until the epic plan is complete and a few epics are executed manually — by then the task patterns are proven and the runner can be built against reality, not guesses.

---

## 8. Quick reference: status transitions

| From | To | Trigger |
|------|----|---------|
| todo | in-progress | agent starts (deps met) |
| in-progress | review-requested | self-review passed |
| in-progress | blocked | can't proceed (§16 filled) |
| blocked | in-progress | blocker resolved |
| review-requested | changes-requested | peer review found issues |
| review-requested | done | peer review approved |
| changes-requested | in-progress | implementer resumes |
| done | verified | human sign-off |
