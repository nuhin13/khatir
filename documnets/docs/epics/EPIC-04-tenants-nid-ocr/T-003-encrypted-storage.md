---
id: T-003
epic: EPIC-04
title: Encrypted image/object storage helper
layer: backend
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-00.T-005]
blocks: [T-005, T-006]
external_services: [s3]
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by: claude
reviewed_at:
reviewed_by:
review_outcome:
---

# T-003 · Encrypted image/object storage helper

## 1. Feature goal
A reusable helper to store/retrieve sensitive files (NID images, payment proofs later) in S3-compatible storage, encrypted, returning opaque keys.

## 2. Business logic
Per `03_env_and_config.md` (S3 env) + `04_coding_conventions.md` (NID encrypted at rest). Files encrypted before upload (or SSE), referenced by opaque key (`photo_ref`); signed-URL retrieval; never public-readable.

## 3. What this task DOES
- `core/storage.py`: `store_encrypted(bytes, kind) -> key`, `signed_url(key, ttl)`, `delete(key)`.
- boto3 against S3-compatible endpoint from env; encryption at rest.
- Tests with a mocked/local S3 (moto or minio).

## 5. Files & changes
### Add
- `khatir/core/storage.py`, `core/tests/test_storage.py`
### Update
- requirements: boto3 (+ moto for tests)

## 6. Database changes
None.
## 7. API changes
None (helper).
## 8. UI changes
No UI.
## 9. External services
S3-compatible storage (env: S3_*). Dev can use MinIO/local.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] store_encrypted returns opaque key
- [x] signed_url with TTL
- [x] delete
- [x] never public-readable; encrypted at rest
- [x] Tests (mocked S3)
- [x] ruff + mypy clean

## 12. Test plan
### Automated
- test_store_and_signed_url, test_not_public, test_delete
### Manual QA
1. Store an image; fetch via signed URL; expires.

## 13. Acceptance criteria
- [x] Encrypted object storage with signed retrieval; tests + lint pass.

## 14. Self-review
- [x] No public ACLs; keys opaque; encrypted
### Deviations from spec
- `core/storage.py` already existed as a filesystem seam (added pre-emptively
  for EPIC-05 T-005). This task delivered the production S3/boto3 backend
  (SSE encryption-at-rest, `private` ACL, presigned GET URLs) and kept the
  filesystem path as a dev/test fallback selected when no `S3_BUCKET` is set,
  so both the same public API and existing consumers keep working.
- Added `S3_SSE` env key (default `AES256`) for the server-side-encryption mode.
### Files touched (actual)
- `apps/api/khatir/core/storage.py` — S3 backend + FS fallback behind one API.
- `apps/api/khatir/core/tests/test_storage.py` — moto-backed S3 tests + FS tests.
- `apps/api/config/settings/base.py` — `S3_*` / `S3_SSE` settings.
- `apps/api/pyproject.toml` — `boto3` dep + `moto[s3]` dev dep.
- `.env.example` — `S3_SSE` key.

## 15. Notes for the implementing agent
- Reused by EPIC-07 (payment proofs) and EPIC-05 (PDFs). Keep it generic with a `kind` prefix (nid/, proof/, pdf/).
