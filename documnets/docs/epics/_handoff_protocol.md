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
