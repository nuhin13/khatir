---
id: T-007
epic: EPIC-13
title: Mobile flag reader (wire EPIC-04 voice flag)
layer: mobile
size: S
status: todo
preferred_agent: codex
depends_on: [T-002]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-007 · Mobile flag reader (wire EPIC-04 voice flag)

## 1. Feature goal
Wire the real FeatureFlag system into the mobile app so flags from /config/public control features in real time.

## 2. Business logic
The mobile app already reads /config/public (EPIC-00 T-007). This task adds a typed `FlagsProvider` reading the `flags` dict and exposes `isEnabled('flag_key')` — then replaces EPIC-04 T-006's placeholder flag check with the real one.

## 3. What this task DOES
- FlagsProvider (from /config/public flags dict); replace EPIC-04 voice flag placeholder; widget test.

## 5. Files & changes
### Add
- lib/core/config/flags_provider.dart; test
### Update
- EPIC-04 add-tenant flow: voice path checks isEnabled('voice_tenant_entry') via FlagsProvider

## 6–10.
No DB; reads /config/public; mobile 🟢; no external; no flags (meta).

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] FlagsProvider reads flags dict from /config/public
- [ ] isEnabled('key') → bool
- [ ] EPIC-04 voice flag wired to real FlagsProvider
- [ ] test: flag on → voice shown; flag off → voice hidden
- [ ] analyze + test pass

## 12. Test plan
### Automated
- flags_provider_test → isEnabled reflects config
## 13. Acceptance criteria
- [ ] Real flag system in mobile; voice flag wired; test passes.
## 14. Self-review
- [ ] EPIC-04 placeholder removed; real provider
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Pattern: FlagsProvider.isEnabled('voice_tenant_entry'). Other features use the same provider as they get flagged.
