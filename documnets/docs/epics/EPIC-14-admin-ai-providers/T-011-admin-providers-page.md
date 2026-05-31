---
id: T-011
epic: EPIC-14
title: Admin AI providers page (Next.js)
layer: admin
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-009, EPIC-11.T-008]
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

# T-011 · Admin AI providers page (Next.js)

## 1. Feature goal
4-category-tab UI for configuring AI providers (chat/voice/ocr/lease) — select vendor, enter model + API key + endpoint, set primary/fallback, test connection.

## 2. Business logic
Per admin spec. Tabs: OCR, Voice, Chat, Lease. Each tab: current primary + fallback providers; edit form; "Test connection" button; DPA warning if applicable. Super+ops.

## 3. What this task DOES
- /ai-providers page; 4 tabs; provider forms; test-connection; DPA warning. Tests.

## 5. Files & changes
### Add
- app/(dashboard)/ai-providers/page.tsx; test
### Update
- sidebar "AI providers" → /ai-providers

## 6–10.
No DB; admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `04_Admin_Portal_Khatir.md` §AI Providers + `ui/KhatirAdmin.jsx`
- Surface: admin · **Lane:** 🟣 admin
- Route: `/(dashboard)/ai-providers`
- 4 category tabs + provider forms + test-connection + DPA warning

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] 4 tabs (OCR/Voice/Chat/Lease)
- [ ] provider form (vendor, model, key, endpoint, primary/fallback)
- [ ] "Test connection" button → shows result
- [ ] DPA warning on OCR tab if non-BD provider
- [ ] super+ops gate
- [ ] TanStack Query; states
- [ ] test: renders; test-connection fires
- [ ] tsc pass

## 12. Test plan
### Automated
- ai_providers_page renders tabs; test-connection fires
## 13. Acceptance criteria
- [ ] AI providers page; 4 tabs; test-connection; DPA warning; tests pass.
## 14. Self-review
- [ ] DPA warning visible; API key masked in display
### Deviations from spec
### Files touched (actual)
## 15. Notes
- API key shown as "••••••••••" after save — never shown in plaintext again in the UI.
