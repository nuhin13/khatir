---
id: T-006
epic: EPIC-00
title: Celery + Celery Beat wiring
layer: backend
size: S
status: todo
preferred_agent: claude-code
depends_on: [T-004]
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

# T-006 · Celery + Celery Beat wiring

## 1. Feature goal
Wire Celery (task queue) and Celery Beat (scheduled tasks) into the Django project so later epics can run background jobs (rent reminders, WhatsApp/SMS sends, OCR, AI calls, nightly cleanup).

## 2. Business logic
Redis is the broker + result backend (from env). Beat uses `django-celery-beat` (DB-backed schedule). No real tasks yet — just the plumbing and a debug ping task.

## 3. What this task DOES
- `config/celery.py` app instance; autodiscover tasks across `khatir.*`.
- Wire broker/result backend from env (`CELERY_BROKER_URL`, `CELERY_RESULT_BACKEND`).
- Add `django-celery-beat` to settings + migrations.
- A `core/tasks.py` debug `ping` task returning "pong".
- Compose services: `worker` (celery worker) and `beat` (celery beat), reusing the api image.
- Test settings run Celery eagerly (`CELERY_TASK_ALWAYS_EAGER=True` in test).

## 4. What this task does NOT do
- No real domain tasks (those live in their epics).

## 5. Files & changes
### Add
- `apps/api/config/celery.py`
- `apps/api/khatir/core/tasks.py` (ping)
- `apps/api/khatir/core/tests/test_celery.py`
### Update
- `apps/api/config/__init__.py` — load celery app
- `config/settings/base.py` — celery config + register `django_celery_beat`
- `config/settings/test.py` — eager mode
- `docker-compose.yml` — add `worker` + `beat` services
### Delete
- none

## 6. Database changes
- `django_celery_beat` migrations (its own tables). No domain tables.

## 7. API changes
No API changes.

## 8. UI changes
No UI changes.

## 9. External services
None. Uses local Redis.

## 10. Feature flags
None.

## 11. Implementation checklist
- [ ] celery app in config/celery.py, autodiscover
- [ ] broker/backend from env
- [ ] django-celery-beat registered + migrated
- [ ] core.tasks.ping debug task
- [ ] worker + beat compose services
- [ ] eager mode in test settings
- [ ] test_celery: ping returns pong

## 12. Test plan
### Automated
- test_celery → ping.delay().get() == "pong" (eager)
### Manual QA
1. `docker compose up worker beat` → both start, worker logs "celery@... ready".
2. From shell: `ping.delay()` → result "pong".

## 13. Acceptance criteria
- [ ] Worker + beat start via compose.
- [ ] ping task runs (eager in tests, real via worker).

## 14. Self-review
- [ ] Broker/backend from env, not hardcoded
- [ ] Eager mode only in test
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Use distinct Redis DBs for cache vs broker vs result (see `.env.example`: /0 cache, /1 broker, /2 result).
- Beat schedule entries will be added by later epics (rent reminders, cleanup).
