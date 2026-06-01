# Khatir — Platform Benchmark Harness

The instrument for choosing which CLI agent(s) build Khatir. Build the instrument
*before* racing — otherwise the comparison is vibes, not data.

**Core idea — the benchmark is not throwaway.** Round 1 has every platform build
**EPIC-00 (the foundation)** from a clean repo. You were going to build EPIC-00 anyway;
you're building it N times and keeping the best. The winner's foundation becomes the
real codebase. Round 2 builds **EPIC-05 (the wedge)** *on the winner's foundation* — which
also tests the skill that matters most in real work: being productive in a codebase the
agent didn't write.

---

## Tournament structure (not round-robin)

| Round | Slice | Who runs | Tests | ~Cost |
|-------|-------|----------|-------|-------|
| **R1 — broad** | EPIC-00 Foundation (16 tasks) | every platform you can run | scaffolding, convention-following, infra, gate compliance | cheap-ish ×N |
| **R2 — deep** | EPIC-05 DMP Form (10 tasks) on R1 winner's repo | top 2–3 survivors only | hard logic, PDF, encryption, working in existing code | bounded |

R1 is broad but eliminates the bottom half. R2 is the discriminating test on survivors only —
mechanical scaffolding doesn't separate platforms; hard logic with a real release gate does.
This keeps the whole benchmark to ~2 days and a bounded token spend.

> EPIC-05 T-010 (DMP template field-verification) is a **human task**, not scored — agents
> can't verify against the real official form. Run it as a parallel human track. For the
> benchmark, score everything in EPIC-05 *except* T-010's real-form verification; use a
> placeholder template so the PDF pipeline is still exercised.

---

## Fairness rules (identical for every platform)

1. **Same starting point.** Clean checkout at the same commit. R2 starts from R1-winner's commit.
2. **Same rules file.** The canonical `AGENTS.md` (synced to each platform's filename — see `sync-agent-rules.sh`). No per-platform prompt tuning.
3. **Same first prompt** (below, verbatim).
4. **Same definition of done.** A task is done only when §11 checklist is filled with git hashes, §13 acceptance criteria met, §14 self-review filled, `make test && make lint` green, committed.
5. **Same clock rules.** Wall-clock from first prompt to "epic done." Pauses for human review count as review time (logged separately), not agent time.
6. **One operator, one screen each.** Don't help an agent beyond unsticking it — and log every unstick (that's the Autonomy metric).

### The canonical first prompt (paste verbatim into each platform)

```
Read docs/architecture/00_overview.md, then 01 through 07 and enums.md.
Then read docs/epics/_handoff_protocol.md and _task_template.md.
Confirm in 3 sentences that you understand the project, the execution model,
and the screen-coverage rule.

Then execute the tasks in docs/epics/EPIC-00-foundation/ in dependency order,
starting with T-001. For each task: implement exactly section 3 (and not section 4),
honor any design anchor in section 8, check off section 11 as you go appending the
short git hash, run `make test && make lint`, fill section 14 self-review, commit,
and update the epic _checklist.md. Stop and tell me when the whole epic is done or
if you are blocked.
```

For R2, swap the epic folder to `EPIC-05-dmp-form/` and add: *"You are working in an
existing codebase you did not write; read the relevant existing modules first."*

---

## The rubric (objective, weighted)

Score each platform **per epic**. Weights tuned for *best output with a minimal team* —
Autonomy is weighted high because an agent that needs babysitting is worse than a slightly
pricier one that runs clean.

| # | Metric | Definition | How to measure | Weight |
|---|--------|-----------|----------------|--------|
| 1 | **Correctness** | Does it actually work? | `make test` pass % × acceptance-criteria (§13) met % | **30** |
| 2 | **Autonomy** | Did it run unattended? | `10 − (unstick_count)`, floored at 0, normalized | **20** |
| 3 | **Fidelity** | Did it build what the spec said? | `10 − (deviation_count)`: skipped §4 boundary, misread/ignored §8 design anchor, invented deps, scope creep | **15** |
| 4 | **Gate compliance** | Did it follow the protocol? | checklist points: §11 filled w/ hashes (2), §14 done (2), lint+test actually run (2), correct commits (2), `_checklist.md` updated (2) → /10 | **15** |
| 5 | **Cost** | Tokens / money for the epic | total $ (or tokens); cheapest = 10, scale others linearly | **10** |
| 6 | **Speed** | Wall-clock to done | fastest = 10, scale others | **5** |
| 7 | **Code quality** | Structure, conventions, no hacks | human 1–5 → ×2 | **5** |

**Weighted score = Σ(metric_normalized_to_10 × weight) / 100**, giving a 0–10 platform score per epic.

### Measurement notes
- **Correctness**: run `make test`; read each task's §13 and tick what's genuinely met (not just claimed).
- **Autonomy**: a tally. Every time you intervene beyond "go" — clarifying, correcting, restarting — is +1 unstick. This is the single most predictive metric for a small team.
- **Fidelity**: diff what was built against §3/§4/§8. Each material miss = +1 deviation. Inventing a library not in the stack doc = deviation. Hardcoding a prototype hex instead of using design-tokens = deviation.
- **Cost**: pull from the platform's usage view / API dashboard. Normalize to USD if plans differ.
- Keep raw numbers; the spreadsheet does the weighting.

---

## Scorecard template

Copy into `docs/agentic/results/scorecard.csv`:

```csv
platform,round,epic,tests_pass_pct,accept_met_pct,unstick_count,deviation_count,gate_points_10,cost_usd,wallclock_min,quality_1to5,weighted_score
claude-code,R1,EPIC-00,,,,,,,,,
codex,R1,EPIC-00,,,,,,,,,
gemini-cli,R1,EPIC-00,,,,,,,,,
opencode,R1,EPIC-00,,,,,,,,,
cursor,R1,EPIC-00,,,,,,,,,
antigravity,R1,EPIC-00,,,,,,,,,
# --- R2 survivors only ---
<winner1>,R2,EPIC-05,,,,,,,,,
<winner2>,R2,EPIC-05,,,,,,,,,
<winner3>,R2,EPIC-05,,,,,,,,,
```

### Weighting formula (drop in a sheet)
```
norm(x, best, worst, higher_is_better):
  if higher_is_better: (x - worst) / (best - worst) * 10
  else:                (worst - x) / (worst - best) * 10

correctness = (tests_pass_pct/100 * accept_met_pct/100) * 10
autonomy    = max(0, 10 - unstick_count)
fidelity    = max(0, 10 - deviation_count)
gate        = gate_points_10
cost        = norm(cost_usd, min_cost, max_cost, higher_is_better=false)
speed       = norm(wallclock_min, min_time, max_time, higher_is_better=false)
quality     = quality_1to5 * 2

weighted_score = (correctness*30 + autonomy*20 + fidelity*15
                + gate*15 + cost*10 + speed*5 + quality*5) / 100
```

---

## Retro template (one per platform per round)

Copy into `docs/agentic/results/<platform>-<round>-retro.md`:

```markdown
# Retro — <platform> — <round> — <epic>

## Summary
- Final weighted score: __ / 10
- Tasks completed clean (no human fix): __ / N
- Tasks needing intervention: __

## What it did well
-

## Where it drifted (the failure catalog — be specific)
- [ ] Misread/ignored a design anchor (§8)? which task:
- [ ] Crossed a §4 "does NOT do" boundary? which:
- [ ] Invented a dependency / wrong library version (vs stack doc)?
- [ ] Hardcoded values instead of using config / design-tokens?
- [ ] Skipped tests or lint, or faked the §11 checklist?
- [ ] Lost the plot over a long session (context drift)?
- [ ] Hallucinated file paths / APIs?
- [ ] Broke the "stop for review" contract (kept going)?

## "What I asked vs what it did" (the deltas)
| Task | Spec said | Agent did | Gap severity |
|------|-----------|-----------|--------------|

## Cost / token notes
- Total $: __  | per completed-clean task: __

## Operator experience (1–5) + why
-

## Verdict
- Best suited for which lane (backend/mobile/admin/infra)?
- Trust level for unattended runs (1–5):
```

---

## Decision output (end of R2)

Produce `docs/agentic/results/RANKING.md`:

```markdown
# Platform Ranking — decided <date>

| Rank | Platform | R1 | R2 | Weighted | Best lane | Notes |
|------|----------|----|----|----------|-----------|-------|

## Lane assignments (feeds WORKFLOW.md)
- 🔵 backend  → <platform>  (most logic / security / money)
- 🟢 mobile   → <platform>  (mechanical, design-anchored screens)
- 🟣 admin    → <platform>  (CRUD-heavy Next.js — cheapest competent)
- ⚙️ infra    → <platform>  (whoever did EPIC-00 cleanest)

## preferred_agent validation
Our task files hint `preferred_agent: claude-code | codex`. Did the data confirm it?
- Confirmed / Revised because: ___
```

That `RANKING.md` is the bridge: it turns the benchmark into the parallel-execution plan
in `WORKFLOW.md`.
