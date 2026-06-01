# Platform Benchmark Rubric

Bake-off epics (same on all 4 platforms): EPIC-00 (scaffold) + EPIC-01 (auth, full-stack).

Score each metric 0–10; weighted total = ranking.

| Metric | Weight | How to score |
|--------|--------|--------------|
| Feature completion % | 0.25 | tasks fully meeting acceptance / total |
| Tests pass ratio | 0.15 | passing / written; 0 if none written |
| Rework / mistake ratio | 0.15 | inverse of (re-runs + reverted commits) |
| Plan adherence | 0.15 | asked-vs-done; penalize scope drift + skipped steps |
| Token + $ cost | 0.15 | normalized inverse cost across the 4 runs |
| Wall-clock | 0.05 | normalized inverse time |
| Code quality | 0.07 | reviewer score: conventions, tokens-not-hardcoded, structure |
| Self-recovery | 0.03 | handled its own errors without human help? |

Weighted total per platform → rank 1..4. Human spot-checks top 2.
