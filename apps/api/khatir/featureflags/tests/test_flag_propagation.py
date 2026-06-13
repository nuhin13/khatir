"""Flag propagation regression test — EPIC-13.T-008.

Asserts the full chain: toggling a flag through the admin API busts the
public-config cache so the change is visible on the *very next* ``/config/public``
read (well within the <60s propagation budget, task §1). Pairs with EPIC-12
T-010, which proves the same pattern for tunable config values.

Unlike ``test_flag_endpoints.py`` (which unit-tests CRUD/toggle/auth in
isolation), this file is a single end-to-end propagation guard: prime the cache,
toggle via the real admin endpoint, re-read the public config — no internal
cache plumbing is touched, only the HTTP surfaces a client actually uses.
"""

from __future__ import annotations

import pytest
from django.core.cache import cache
from rest_framework.test import APIClient

from khatir.admin_portal.auth_tokens import issue_access_token
from khatir.admin_portal.tests.factories import AdminUserFactory
from khatir.core.enums import AdminRole
from khatir.featureflags.enums import FlagScope
from khatir.featureflags.tests.factories import FeatureFlagFactory

FLAGS_URL = "/admin/api/flags"
CONFIG_PUBLIC_URL = "/api/v1/config/public"

pytestmark = pytest.mark.django_db


@pytest.fixture(autouse=True)
def _clear_cache() -> None:
    """Start each test from an empty cache so reads rebuild deterministically."""
    cache.clear()


def _super_client() -> APIClient:
    admin = AdminUserFactory(role=AdminRole.SUPER)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


def _public_flag(anon: APIClient, key: str) -> bool:
    return anon.get(CONFIG_PUBLIC_URL).json()["flags"][key]


def test_flag_toggle_propagates_to_config_public() -> None:
    """Toggle a global flag via admin → next /config/public read reflects it.

    Reads the public config first (priming the 60s cache with the flag OFF),
    then toggles through the admin endpoint, then re-reads: the cache must have
    been busted so the new value appears immediately — not after the TTL.
    """
    flag = FeatureFlagFactory(
        key="t008_propagate", enabled=False, scope=FlagScope.GLOBAL
    )
    anon = APIClient()
    admin = _super_client()

    # Prime the public-config cache with the flag OFF.
    assert _public_flag(anon, flag.key) is False

    # Admin toggles it ON; propagation is immediate (cache busted on write).
    resp = admin.patch(f"{FLAGS_URL}/{flag.key}/toggle")
    assert resp.status_code == 200, resp.content
    assert resp.json()["enabled"] is True

    # Next public read sees ON without waiting out the TTL.
    assert _public_flag(anon, flag.key) is True

    # And toggling back OFF propagates just as immediately (regression both ways).
    assert admin.patch(f"{FLAGS_URL}/{flag.key}/toggle").status_code == 200
    assert _public_flag(anon, flag.key) is False
