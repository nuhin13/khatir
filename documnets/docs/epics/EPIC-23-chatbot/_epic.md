# EPIC-23 · In-App Chatbot (Support & Guidance)

**Phase:** P1 · **Status:** todo · **Depends on:** EPIC-14
**Tasks:** 8 · **External services:** AI chat provider (via AI gateway)

---

## Business goal
An in-app assistant that answers landlord/tenant questions ("how do I generate a DMP form?", "what's my collection this month?") and guides users — reducing support load and improving activation, powered by the AI gateway (chat category).

## User-visible outcome
A chat button opens an assistant that answers product + tenancy questions in Bangla/English, can reference the user's own data (with scoping), and links to the right screen. Grounded, scoped, and safe (no legal/financial advice beyond disclaimers).

## Scope
**In:** Chat UI (in-app), chat endpoint routing through the AI gateway (chat category), conversation history, tool-style data lookups scoped to the user (their portfolio/rent summary), guardrails + disclaimers. Bilingual.
**Out:** Voice chat. Cross-user data. Autonomous actions (read-only guidance; no money moves).

## Dependencies
EPIC-14 (AI gateway chat provider), EPIC-09 (data the bot can summarize), EPIC-13 (chatbot_enabled flag).

## Data-model changes
- `ChatConversation` + `ChatMessage`: user FK, role (user/assistant), content, created_at.

## API surface
- `POST /api/v1/chat` — send a message → assistant reply (via gateway, user-scoped context).
- `GET /api/v1/chat/history` — conversation history.

## UI screens
- No dedicated ledger screen — the chatbot is an overlay/sheet reachable from the existing shells (design uses a chat affordance, not a numbered prototype screen). Built as a reusable chat sheet.

## Feature flags introduced
- `chatbot_enabled` (default on; kill-switchable).

## Acceptance criteria (epic-level)
- [ ] User chats with the assistant; replies via the AI gateway (chat category).
- [ ] Assistant can summarize the user's OWN data only (scoped); never another user's.
- [ ] Guardrails: no definitive legal/financial advice; disclaimers; refuses out-of-scope.
- [ ] Conversation history persists per user.
- [ ] Kill-switchable.
- [ ] `make test` + `make lint` pass.

## Task list
| Task | Title | Layer | Size | Depends on |
|------|-------|-------|------|-----------|
| T-001 | ChatConversation + ChatMessage models | backend | S | EPIC-00.T-005 |
| T-002 | Chat endpoint (gateway + user-scoped context) | backend | M | T-001, EPIC-14.T-007 |
| T-003 | Scoped data tools (own portfolio/rent summary) | backend | M | T-002, EPIC-09.T-001 |
| T-004 | Guardrails + disclaimers | backend | S | T-002 |
| T-005 | Seed chatbot config + flag | backend | XS | EPIC-13.T-001 |
| T-006 | Flutter chat sheet UI | mobile | M | T-002 |
| T-007 | Chat data layer (mobile) | mobile | S | T-002 |
| T-008 | Chat scoping + guardrail test | cross-cutting | S | T-003, T-004 |

## Risks & mitigations
| Risk | Mitigation |
|------|-----------|
| Bot leaks another user's data | T-003 tools strictly scoped to request.user; T-008 asserts no cross-user access |
| Bot gives legal/financial advice | T-004 guardrails + disclaimers; refuses + redirects to a professional |
| Prompt injection via user data | Sanitize tool outputs; system prompt hardening; gateway-side limits |
| Cost overrun | Usage logged (EPIC-14); rate-limit per user |
