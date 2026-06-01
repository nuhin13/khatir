# Blind Judge Agent

Inputs: the 4 run records + the 4 produced codebases (anonymized as A/B/C/D), `RUBRIC.md`.
Do NOT know which platform is which.

For each anonymized run:
1. Score every rubric metric 0–10 with a one-line justification.
2. Compute the weighted total.
Then output a ranking table A–D and the single highest-confidence winner, plus the top weakness of each.
Output only the table + justifications. No praise, no filler.
