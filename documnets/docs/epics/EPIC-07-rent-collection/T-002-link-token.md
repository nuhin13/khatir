---
id: T-002
epic: EPIC-07
title: Signed link-token service
layer: backend
size: S
status: todo
preferred_agent: claude-code
depends_on: [T-001]
blocks: [T-003, T-005]
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · Signed link-token service

## 1. Feature goal
Generate + validate signed, single-purpose, expiring tokens that grant access to exactly one rent request's web page — no login.

## 2. Business logic
Token encodes the rent_request id + expiry, signed (itsdangerous / Django signing). TTL from config (rent_link_token_ttl_hours). Validation returns the request or raises invalid/expired. Not guessable; one token = one request.

## 3. What this task DOES
- `rent/tokens.py`: make_token(rent_request), resolve_token(token) → RentRequest or error. Tests (valid/expired/tampered).

## 5. Files & changes
### Add
- rent/tokens.py, tests/test_tokens.py

## 6. Database changes
Stores token on RentRequest.
## 7. API changes
None (used by T-003/005).
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] make_token signs request id + expiry
- [ ] resolve_token validates (invalid/expired/tampered)
- [ ] TTL from config
- [ ] one token = one request
- [ ] Tests: valid, expired, tampered
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_valid_token, test_expired, test_tampered
### Manual QA
1. Generate + resolve a token.

## 13. Acceptance criteria
- [ ] Secure single-purpose expiring tokens; tests + lint pass.

## 14. Self-review
- [ ] Signed; not guessable; TTL from config
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Use Django signing / itsdangerous; sign with a dedicated secret. Store the issued token on the RentRequest for lookup.
