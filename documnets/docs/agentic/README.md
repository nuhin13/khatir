# docs/agentic — Agentic Development System

The reusable system for building Khatir (and future projects) with multiple CLI agents.
Platform-agnostic core, thin per-platform shims.

## Files

| File | What it is | When you use it |
|------|-----------|-----------------|
| `AGENTS.md` | The ONE canonical agent-rules file (the contract every agent follows) | edit here; never edit the generated copies |
| `sync-agent-rules.sh` | Fans `AGENTS.md` out to each CLI's expected filename (+ shim) | run once at setup + after editing AGENTS.md |
| `shims/<platform>.md` | Thin per-platform tool/MCP wiring (appended by the sync script) | edit when a platform's tooling changes |
| `BENCHMARK.md` | The tournament that ranks platforms on *your* epics (R1=EPIC-00, R2=EPIC-05) | days 1–2; produces `results/RANKING.md` |
| `WORKFLOW.md` | The parallel-execution playbook (lanes, per-task loop, cadence, gates) | every build day |
| `results/` | scorecard.csv, retros, reviews/, RANKING.md | filled during benchmark + build |

## The flow

```
1. Day 0:  sync-agent-rules.sh  +  dry-run one task end-to-end
2. Day 1:  BENCHMARK R1  (all platforms build EPIC-00; keep the winner's foundation)
3. Day 2:  BENCHMARK R2  (survivors build EPIC-05 on winner's repo) -> RANKING.md
4. Day 3+: WORKFLOW.md   (lanes run in parallel; agents implement + peer-review; humans adjudicate)
5. Day 10: hard gates + EPIC-16 T-009 completion report -> publish
```

## The two ideas that make it work

1. **The benchmark isn't wasted** — Round 1 builds your real foundation 5 ways and keeps the best.
2. **Agents coordinate through git + task frontmatter, never directly** — so the system is genuinely
   platform-agnostic and a Claude agent + a Codex agent collaborate without knowing about each other.

Open questions still to settle (they tune weights + cadence, not structure): **budget tolerance,
team size, which platforms you can run today.** Answer those and the cadence in WORKFLOW.md gets
its final numbers.
