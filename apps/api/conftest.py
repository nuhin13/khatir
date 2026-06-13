"""Pytest root configuration and shared fixtures."""

from collections.abc import Iterator

import pytest
from django.core.cache import cache
from rest_framework.test import APIClient


@pytest.fixture(autouse=True)
def _clear_cache() -> Iterator[None]:
    """Reset the (process-wide LocMem) cache between tests.

    ``get_config`` caches SystemConfig values for 60s; without this the cache
    would leak across tests and make config-dependent assertions order-sensitive.
    """
    cache.clear()
    yield
    cache.clear()


@pytest.fixture
def api_client() -> APIClient:
    """Unauthenticated DRF test client."""
    return APIClient()
