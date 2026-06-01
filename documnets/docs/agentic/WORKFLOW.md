# WORKFLOW.md — Khatir Parallel Agentic Build Playbook

How a minimal human team turns 302 task specs into shipped software in ~10 days using
multiple CLI agents in parallel. Platform-agnostic; lane assignments come from
`docs/agentic/results/RANKING.md` (produced by the benchmark).

---

## The mental model

- **Agents never talk to each other directly.** They coordinate through **git + the task files'
  frontmatter**. This is durable, stateless, and platform-agnostic — an agent on Claude and an
  agent on Codex coordinate fine because they read/write the same files.
- **The dispatcher is `make next`.** It reads the dependency graph + each task's `status` and hands
  out the next ready task in a lane. No central server, no message bus.
- **The bottleneck is human review, not agent speed.** Everything below optimizes review throughput.

```
 task spec ──> agent implements (branch) ──> peer-AI review (verdict file) ──> human merges ──> next
   (todo)         (in_progress)                  (in_review)                     (done)
```

---

## Roles (map to your real, minimal team)

You can collapse these onto 1–2 people. They are *hats*, not headcount.

| Hat | Does | Human or agent |
|-----|------|----------------|
| **Dispatcher / TL** | runs `make next` per lane, assigns to the right agent, merges, keeps the board honest | human (you) |
| **Implementer** | executes one task spec → branch → PR | **agent** (per lane) |
| **Peer reviewer** | reviews the diff against §13, writes PASS/CHANGES verdict | **agent** (a *different/cheaper* model than the implementer) |
| **Integrator / QA** | runs full `make test`, screen-coverage, integration after each epic | human + QA agent |
| **Gatekeeper** | owns the hard gates (DMP template T-010, MVP completion T-009, legal-safety tests) | **human** |

The trick to "minimal team": **agents implement and pre-review; humans only adjudicate.**

---

## Lane parallelism

Four lanes run concurrently once the foundation exists:

```
🔵 backend   make next LAYER=backend   -> strongest reasoner   (logic, security, money)
🟢 mobile    make next LAYER=mobile    -> 2nd platform         (mechanical, design-anchored)
🟣 admin     make next LAYER=admin     -> cheapest competent   (CRUD-heavy Next.js)
⚙️ infra     make next LAYER=infra     -> cleanest-at-EPIC-00
```

**Sequencing reality (do not fight it):** EPIC-00 blocks everything; 01/02 block most. So days 1–2
are necessarily near-sequential (and double as the benchmark). True 4-lane parallelism starts ~day 3
once Foundation + Auth + Roles exist. The `depends_on` graph enforces this automatically — `make next`
simply won't hand out a task whose deps aren't `done`.

### Avoiding collisions
- One agent per lane at a time. Two agents in the same lane will fight over shared files.
- Cross-lane deps are explicit (`EPIC-NN.T-XXX`); a lane blocks cleanly until its dep is `done`.
- If two lanes must touch the same module (rare), the later one waits — encode it as a dep.

---

## The per-task loop (what actually happens)

1. **Dispatch.** Dispatcher runs `make next LAYER=<lane>` → gets `T-XXX`. Confirms its `preferred_agent`
   hint; assigns to that lane's agent. Sets `status: in_progress`, `executed_by: <platform>`.
2. **Implement.** Agent follows the AGENTS.md contract → branch `epic-NN/t-XXX` → §11 checklist with
   hashes → `make test && make lint` → §14 self-review → commit → **stop**.
3. **Peer review.** A *second* agent (cheaper model) reviews the diff against §3/§4/§8/§13 → writes
   `docs/agentic/results/reviews/T-XXX.md` = **PASS** or **CHANGES NEEDED** + concrete bullets.
4. **Human adjudicate.** You read the *verdict + diff + §14*, not raw code cold. PASS → merge,
   `status: done`, tick `_checklist.md`. CHANGES → bounce back to the implementer with the verdict.
5. **Next.** Dispatcher pulls the next ready task. Repeat.

> This is why tasks are sized XS/S/M: a small diff + a peer verdict is a 2–5 minute human decision.
> That's the whole game for a tiny team.

---

## Daily cadence (10-day MVP target, EPIC-00→16)

| Day | Focus | Lanes active |
|-----|-------|--------------|
| 0 | Build harness; sync rules (`sync-agent-rules.sh`); dry-run one task | — |
| 1 | **R1 benchmark** = every platform builds EPIC-00. Score that night. | (benchmark) |
| 2 | **R2 benchmark** = survivors build EPIC-05 on winner's repo. Rank → `RANKING.md`. Keep winner's EPIC-00. | (benchmark) |
| 3 | EPIC-01 Auth + EPIC-02 Roles (still mostly sequential) | backend, then mobile |
| 4 | Fan out: EPIC-03 Properties (🟢) ∥ EPIC-11 Admin Foundation (🟣) ∥ infra hardening | 🟢 🟣 ⚙️ |
| 5 | EPIC-04 Tenants/OCR (🔵+🟢) ∥ EPIC-12 Admin Pricing/Users (🟣) | 🔵 🟢 🟣 |
| 6 | EPIC-05 wedge finalize (🔵+🟢) ∥ EPIC-13/14 Admin flags+AI gateway (🟣⚙️) — **DMP template (T-010) human track** | all 4 |
| 7 | EPIC-06 Lease ∥ EPIC-07 Rent collection (🔵+🟢) ∥ EPIC-15 Notifications (🟣) | all 4 |
| 8 | EPIC-08 Maintenance ∥ EPIC-09 Dashboard (🔵+🟢) ∥ EPIC-16 Audit/Compliance (🟣) | all 4 |
| 9 | EPIC-10 Pricing/free-limit; integration; fix the peer-review backlog | 🔵 🟢 🟣 |
| 10 | Full `make test` + `make screen-coverage` + **EPIC-16 T-009 completion report**; publish | QA + human |

This is aggressive and assumes the benchmark winners run clean. If review backs up, the **review
queue is the throttle** — slow the implementers, never skip review. Slipping to 12–14 days with
clean gates beats hitting 10 with an unreviewed mess.

---

## Cost / token optimization (operational)

- **Right-size the model to the task.** Honor `size` + `preferred_agent`: `XS/S` mechanical → cheap/fast
  model; `L`/architectural → expensive reasoner. Wire the dispatcher to suggest the model.
- **Batch a lane in one session** so the rules + conventions context is cached, not cold-started per task.
- **Peer-review with a cheaper model** than the implementer — reviewing is easier than writing.
- **Keep AGENTS.md tight** — it's the biggest cached prompt; bloat is paid on every call.
- **Track $/clean-task**, not $/task. An agent that's cheap but needs 3 reworks is expensive.

---

## Hard gates (a human owns each; agents cannot self-pass)

1. **DMP template verification** — EPIC-05 T-010. Needs the real official form. Human-provided. The
   wedge cannot ship without it. Run as a parallel track from day 1.
2. **Legal-safety tests** — EPIC-21 T-009 (no public reputation), EPIC-24 T-010 (no landlord lookup),
   EPIC-20 T-010 (no cross-landlord). These must pass before warnings/reviews/history ever enable.
3. **Screen coverage** — `make screen-coverage` = 0 TBD before MVP close.
4. **MVP completion report** — EPIC-16 T-009. Verifies all 196 MVP tasks done + gates green.

---

## Failure handling

- **Agent drifts mid-epic** (context rot): stop it, reset to last green commit, re-dispatch the single
  failing task with a fresh session. Don't let it "fix forward" indefinitely.
- **Two agents collide on a file**: the lane discipline failed — serialize via a dep and redo.
- **Peer review and human disagree**: human wins; capture why in the retro to tune AGENTS.md.
- **A platform underperforms its benchmark in real work**: re-assign its lane to the runner-up from
  `RANKING.md`. The workflow is agnostic — swapping a lane's platform changes nothing else.

---

## Bootstrapping checklist (do this once, Day 0)

- [ ] `./docs/agentic/sync-agent-rules.sh` — generate per-platform rules files; commit them.
- [ ] Confirm `make next`, `make next LAYER=…`, `make test`, `make lint`, `make screen-coverage` work.
- [ ] Create `docs/agentic/results/` (scorecard.csv, retros, reviews/, RANKING.md).
- [ ] Dry-run the per-task loop on a single XS task end-to-end (implement → peer review → merge) to
      shake out tooling before the real race.
- [ ] Assign the human Gatekeeper for the four hard gates.
