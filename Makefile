# Khatir mono-repo Makefile (T-011)
#
# One set of verbs for the whole repo. Run everything from the repo root.
#
# Conventions
#   Stack    : docker compose (services in ./docker-compose.yml)
#   Backend  : uv-managed Django in apps/api (uv run ...)
#   Mobile   : Flutter in apps/mobile (flutter ...)
#   Admin    : Next.js in apps/admin (npm run ...)
#   Tracker  : python3 infra/scripts/tracker.py (T-012)
#
# `make` / `make help` prints every target with its description.

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
COMPOSE   := docker compose
API_DIR   := apps/api
MOBILE_DIR:= apps/mobile
ADMIN_DIR := apps/admin
TRACKER   := python3 infra/scripts/tracker.py
FLUTTER   := flutter
LAYER     ?=

# Django settings module for local (host) management commands.
DJANGO_SETTINGS ?= config.settings.dev

.DEFAULT_GOAL := help

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
.PHONY: help
help: ## List all targets with descriptions
	@echo "Khatir — make targets:"
	@echo ""
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "} {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Notes:"
	@echo "  Backend cmds run via 'uv run' inside $(API_DIR) (no container needed)."
	@echo "  make next LAYER=backend|mobile|admin|infra  narrows the tracker lane."

# ---------------------------------------------------------------------------
# Stack (docker compose)
# ---------------------------------------------------------------------------
.PHONY: up down logs ps restart
up: ## Start the full stack in the background
	$(COMPOSE) up -d

down: ## Stop the stack and remove containers
	$(COMPOSE) down

logs: ## Tail logs from all services
	$(COMPOSE) logs -f

ps: ## Show running service status
	$(COMPOSE) ps

restart: ## Restart all services
	$(COMPOSE) restart

# ---------------------------------------------------------------------------
# Database / Django management (run in the api container)
# ---------------------------------------------------------------------------
.PHONY: migrate makemigrations superuser dbshell
migrate: ## Apply Django migrations (api container)
	$(COMPOSE) exec api python manage.py migrate

makemigrations: ## Generate Django migrations (api container)
	$(COMPOSE) exec api python manage.py makemigrations

superuser: ## Create a Django superuser (api container)
	$(COMPOSE) exec api python manage.py createsuperuser

dbshell: ## Open a psql shell on the db service
	$(COMPOSE) exec db psql -U $${DB_USER:-khatir} -d $${DB_NAME:-khatir}

# ---------------------------------------------------------------------------
# Backend (apps/api — uv-managed Django)
# ---------------------------------------------------------------------------
.PHONY: api-shell api-test api-lint api-install
api-install: ## Install backend dependencies (uv sync)
	cd $(API_DIR) && uv sync

api-shell: ## Open the Django shell (uv run, host)
	cd $(API_DIR) && DJANGO_SETTINGS_MODULE=$(DJANGO_SETTINGS) uv run python manage.py shell

api-test: ## Run backend test suite (pytest via uv)
	cd $(API_DIR) && uv run pytest

api-lint: ## Lint backend with ruff (via uv)
	cd $(API_DIR) && uv run ruff check .

# ---------------------------------------------------------------------------
# Mobile (apps/mobile — Flutter)
# ---------------------------------------------------------------------------
.PHONY: mobile-run mobile-test mobile-lint mobile-install
mobile-install: ## Fetch Flutter packages (pub get)
	cd $(MOBILE_DIR) && $(FLUTTER) pub get

mobile-run: ## Run the Flutter app
	cd $(MOBILE_DIR) && $(FLUTTER) run

mobile-test: ## Run the Flutter test suite
	cd $(MOBILE_DIR) && $(FLUTTER) test

mobile-lint: ## Static-analyse the Flutter app
	cd $(MOBILE_DIR) && $(FLUTTER) analyze

# ---------------------------------------------------------------------------
# Admin (apps/admin — Next.js)
# ---------------------------------------------------------------------------
.PHONY: admin-dev admin-build admin-test admin-lint admin-install
admin-install: ## Install admin dependencies (npm install)
	cd $(ADMIN_DIR) && npm install

admin-dev: ## Run the Next.js dev server
	cd $(ADMIN_DIR) && npm run dev

admin-build: ## Build the Next.js admin app
	cd $(ADMIN_DIR) && npm run build

admin-test: ## Run the admin test suite
	cd $(ADMIN_DIR) && npm run test

admin-lint: ## Lint the admin app (eslint)
	cd $(ADMIN_DIR) && npm run lint

# ---------------------------------------------------------------------------
# Aggregate (all apps)
# ---------------------------------------------------------------------------
.PHONY: install test lint format
install: api-install mobile-install admin-install ## Install deps for all apps

test: api-test mobile-test admin-test ## Run all three app test suites

lint: api-lint mobile-lint admin-lint ## Run all three linters

format: ## Format code across all apps
	cd $(API_DIR) && uv run ruff format .
	cd $(MOBILE_DIR) && $(FLUTTER) format lib test || dart format lib test
	cd $(ADMIN_DIR) && npm run format

# ---------------------------------------------------------------------------
# Tracker (T-012 scripts)
# ---------------------------------------------------------------------------
# If the tracker scripts are not yet installed, print a friendly notice
# instead of failing the whole Makefile.
.PHONY: status next review-queue epic-report
status: ## Tracker: status counts + per-epic progress (read-only)
	@test -f infra/scripts/tracker.py \
		&& $(TRACKER) status --no-write \
		|| echo "tracker scripts not installed (infra/scripts/tracker.py — see T-012)"

next: ## Tracker: next ready task (make next LAYER=backend)
	@test -f infra/scripts/tracker.py \
		&& $(TRACKER) next $(if $(LAYER),--layer $(LAYER),) \
		|| echo "tracker scripts not installed (infra/scripts/tracker.py — see T-012)"

review-queue: ## Tracker: list tasks awaiting review
	@test -f infra/scripts/tracker.py \
		&& $(TRACKER) review-queue \
		|| echo "tracker scripts not installed (infra/scripts/tracker.py — see T-012)"

epic-report: ## Tracker: completion report (make epic-report EPIC=00)
	@test -f infra/scripts/tracker.py \
		&& $(TRACKER) epic-report $(EPIC) \
		|| echo "tracker scripts not installed (infra/scripts/tracker.py — see T-012)"
