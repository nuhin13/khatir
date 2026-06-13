---
id: T-007
epic: EPIC-22
title: Manager add-owner screen
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-003]
blocks: []
external_services: []
feature_flags: [b2b_manager_enabled]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-007 · Manager add-owner screen

## 1. Feature goal
Link a new owner (emojiHero 🤝 'Link an owner', 'মালিকের তথ্য দিন'): enter owner phone/info → request → owner consents → active. Shows pending requests.

## 2. Business logic
Link a new owner (emojiHero 🤝 'Link an owner', 'মালিকের তথ্য দিন'): enter owner phone/info → request → owner consents → active. Shows pending requests. Per `mgrAddOwner` design.

## 3. What this task DOES
- mgrAddOwner_screen matching the `mgrAddOwner` design; manager-scoped data; all states. Widget test.

## 5. Files & changes
### Add
- features/manager/presentation/screens/mgrAddOwner_screen.dart; ARB; test
### Update
- router `/manager/add-owner`; manager shell wiring

## 6–10.
No DB; consumes manager endpoints; mobile 🟢 (manager role); flag b2b_manager_enabled.

## 8. UI changes
- **Design source:** screen `mgrAddOwner` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-other.js` → `reg('mgrAddOwner')`)
- Surface: mobile · **Lane:** 🟢 mobile (manager role)
- Route: `/manager/add-owner`
- Translate per design; values from packages/design-tokens
- States: loading / error / empty / data
- i18n keys: mgr_add_owner_phone, mgr_add_owner_request, mgr_add_owner_pending (bn + en) — lift copy from `mgrAddOwner`

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] mgrAddOwner_screen matches design
- [ ] manager-scoped data (active-linked owners)
- [ ] all states
- [ ] route `/manager/add-owner` + manager shell wiring
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- mgrAddOwner_test → renders; manager-scoped
### Manual QA
1. Log in as manager → this screen → correct cross-owner data.

## 13. Acceptance criteria
- [ ] Screen matches `mgrAddOwner` design; manager-scoped; all states.
- [ ] **Screen `mgrAddOwner` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Matches design; tokens; active-linked owners only
### Deviations from spec
### Files touched (actual)
## 15. Notes
Link a new owner (emojiHero 🤝 'Link an owner', 'মালিকের তথ্য দিন'): enter owner phone/info → request → owner consents → active. Shows pending requests.
