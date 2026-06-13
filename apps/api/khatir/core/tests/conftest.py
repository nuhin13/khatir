"""Shared fixtures for core tests.

Defines a concrete ``SoftDeleteModel`` subclass (the base is abstract) and
creates its table in the test DB so soft-delete behavior can be exercised.
"""

from collections.abc import Iterator
from typing import Any

import pytest
from django.db import connection, models

from khatir.core.models import SoftDeleteModel


class _SoftDeleteThing(SoftDeleteModel):
    name = models.CharField(max_length=50)

    class Meta:
        app_label = "core"


@pytest.fixture(scope="session")
def _soft_delete_table(django_db_setup: Any, django_db_blocker: Any) -> Iterator[None]:
    with django_db_blocker.unblock(), connection.schema_editor() as schema_editor:
        schema_editor.create_model(_SoftDeleteThing)
    yield
    with django_db_blocker.unblock(), connection.schema_editor() as schema_editor:
        schema_editor.delete_model(_SoftDeleteThing)


@pytest.fixture
def soft_delete_model(_soft_delete_table: None) -> type[_SoftDeleteThing]:
    return _SoftDeleteThing
