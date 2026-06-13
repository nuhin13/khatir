---
id: T-002
epic: EPIC-07
title: Signed link-token service
layer: backend
size: S
status: done
preferred_agent: claude-code
depends_on: [T-001]
blocks: [T-003, T-005]
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by: claude
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
- [x] make_token signs request id + expiry
- [x] resolve_token validates (invalid/expired/tampered)
- [x] TTL from config
- [x] one token = one request
- [x] Tests: valid, expired, tampered
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_valid_token, test_expired, test_tampered
### Manual QA
1. Generate + resolve a token.

## 13. Acceptance criteria
- [x] Secure single-purpose expiring tokens; tests + lint pass.

## 14. Self-review
- [x] Signed; not guessable; TTL from config
### Deviations from spec
None. Token signed with Django `TimestampSigner` under a dedicated salt
(`khatir.rent.link_token`); TTL read from `rent_link_token_ttl_hours` config
(72h fallback until T-009 seeds it). `make_token` persists the token on
`RentRequest.link_token`. `resolve_token` raises typed `ExpiredLinkToken` /
`InvalidLinkToken` (both subclass `NotFoundError`) so the T-005 web page can
distinguish 410 from 404 while JSON callers still see an opaque 404.
### Files touched (actual)
- khatir/rent/tokens.py
- khatir/rent/tests/test_tokens.py

## 15. Notes for the implementing agent
- Use Django signing / itsdangerous; sign with a dedicated secret. Store the issued token on the RentRequest for lookup.
