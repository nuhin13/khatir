---
id: T-007
epic: EPIC-13
title: Mobile flag reader (wire EPIC-04 voice flag)
layer: mobile
size: S
status: done
preferred_agent: codex
depends_on: [T-002]
blocks: []
external_services: []
feature_flags: []
started_at: 2026-06-05
completed_at: 2026-06-05
executed_by: claude
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
- [x] FlagsProvider reads flags dict from /config/public
- [x] isEnabled('key') → bool
- [x] EPIC-04 voice flag wired to real FlagsProvider
- [x] test: flag on → voice shown; flag off → voice hidden
- [x] analyze + test pass

## 12. Test plan
### Automated
- flags_provider_test → isEnabled reflects config
## 13. Acceptance criteria
- [x] Real flag system in mobile; voice flag wired; test passes.
## 14. Self-review
- [x] EPIC-04 placeholder removed; real provider
### Deviations from spec
- The prior per-flag `PublicConfig.voiceTenantEntry` field is replaced by a
  generic `flags` map on `PublicConfig` plus a typed `FlagsProvider`
  (`Flags.isEnabled('key', {orElse})`). `voiceTenantEntry` is kept only as a
  thin convenience getter over the map for backward compatibility. The
  add-tenant chooser and voice-fill screen now gate on
  `flagsProvider.isEnabled('voice_tenant_entry', orElse: true)` instead of
  reading the field directly — new features wire up by passing a flag key with
  no provider changes.
### Files touched (actual)
- Add: lib/core/config/flags_provider.dart, test/flags_provider_test.dart
- Update: lib/core/config/public_config_provider.dart (generic flags map +
  `_parseFlags`, `PublicConfig.withVoice` factory, `voiceTenantEntry` getter),
  lib/features/tenants/presentation/screens/add_tenant_screen.dart,
  lib/features/tenants/presentation/screens/voice_fill_screen.dart,
  test/add_tenant_test.dart, test/voice_fill_test.dart
## 15. Notes
- Pattern: FlagsProvider.isEnabled('voice_tenant_entry'). Other features use the same provider as they get flagged.
