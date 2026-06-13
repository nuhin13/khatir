"""Free-tier usage selector (T-008 §3).

Surfaces the landlord/manager's current tenant count against the free-tier
limit so the UI can show "1/2 free" and EPIC-10 can enforce the cap. This is the
**counter only** — it never blocks creation; hard enforcement (requiring an
upgrade) lives in EPIC-10 (T-008 §15).

The count reuses ``Tenant.objects.for_user`` — the single source of tenant
visibility truth (``Tenant → Lease → Unit → Building → owner``) — so the
free-tier count never drifts from what the user can actually see, and
soft-deleted tenants are excluded by the manager's default filter. The free
limit is read from the ``free_tier_tenant_limit`` ``SystemConfig`` key (default
2), never hardcoded, so an admin can raise it without a redeploy
(``06_database_schema.md`` §"Free tier", T-008 §14).
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from khatir.core.config import get_config

from .models import Tenant

FREE_TIER_LIMIT_KEY = "free_tier_tenant_limit"
_DEFAULT_FREE_LIMIT = 2


@dataclass(frozen=True)
class TenantUsage:
    """The caller's tenant count + free-tier status."""

    tenants_used: int
    free_limit: int
    is_over_free: bool


def tenant_usage(user: Any) -> TenantUsage:
    """Return the user's tenant count and free-tier status.

    ``tenants_used`` is the number of non-deleted tenants visible to ``user``
    via the lease→unit→building→owner chain. ``free_limit`` comes from the
    ``free_tier_tenant_limit`` config (default 2). ``is_over_free`` is true once
    the count exceeds the limit — a soft signal for the UI/upgrade prompt; this
    selector does not block anything.
    """
    tenants_used = Tenant.objects.for_user(user).count()
    free_limit = int(get_config(FREE_TIER_LIMIT_KEY, _DEFAULT_FREE_LIMIT))
    return TenantUsage(
        tenants_used=tenants_used,
        free_limit=free_limit,
        is_over_free=tenants_used > free_limit,
    )
