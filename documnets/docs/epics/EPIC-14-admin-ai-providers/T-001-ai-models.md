---
id: T-001
epic: EPIC-14
title: AIProvider + AIUsageLog models
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-00.T-005]
blocks: [T-009]
external_services: []
feature_flags: []
started_at: 2026-06-04completed_at: 2026-06-04executed_by: claudereviewed_at:
reviewed_by:
review_outcome:
---

# T-001 · AIProvider + AIUsageLog models

## 1. Feature goal
Models for AI provider configuration and per-call usage tracking.

## 2. Business logic
AIProvider: category (chat/voice/ocr/lease), provider_key, is_primary bool, is_fallback bool, model_name, api_key_enc (encrypted), endpoint_url, params_json, dpa_reference, active. AIUsageLog: provider FK, category, tokens_used, cost_usd Decimal, success, latency_ms, failover_from nullable FK.

## 3. What this task DOES
- ai_providers app; both models; AICategory enum; migration; admin; tests.

## 5. Files & changes
### Add
- khatir/ai_providers/{__init__,apps,models,enums}.py, migration, tests/factories
### Update
- settings register

## 6. Database changes
2 tables. Reversible.
## 7–10.
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] AIProvider (category, keys enc, active, dpa_reference)
- [ ] AIUsageLog (cost Decimal, latency, failover_from)
- [ ] AICategory enum matches spec
- [ ] api_key_enc encrypted (core.encryption)
- [ ] migrations reversible; admin
- [ ] factories + tests
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_provider_create, test_api_key_encrypted, test_usage_log
## 13. Acceptance criteria
- [ ] Models; migration clean; API key encrypted; tests + lint pass.
## 14. Self-review
- [ ] API key encrypted at rest; cost Decimal
### Deviations from spec
### Files touched (actual)
## 15. Notes
- api_key_enc: encrypt with core.encryption before storing. Never log decrypted.
