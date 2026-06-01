"""Tests for base models: timestamps + soft-delete behavior."""

from typing import Any

import pytest

from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db


def test_timestamps_set_on_create() -> None:
    cfg = SystemConfig.objects.create(key="x", value="1", type="int")
    assert cfg.created_at is not None
    assert cfg.updated_at is not None


def test_updated_at_changes_on_save() -> None:
    cfg = SystemConfig.objects.create(key="x", value="1", type="int")
    first = cfg.updated_at
    cfg.value = "2"
    cfg.save()
    cfg.refresh_from_db()
    assert cfg.updated_at >= first


def test_soft_delete_hides_rows(soft_delete_model: type[Any]) -> None:
    obj = soft_delete_model.objects.create(name="a")
    pk = obj.pk
    obj.delete()
    # Default manager excludes deleted.
    assert not soft_delete_model.objects.filter(pk=pk).exists()
    # all_objects still sees it, marked deleted.
    revived = soft_delete_model.all_objects.get(pk=pk)
    assert revived.deleted_at is not None
    assert revived.is_deleted is True


def test_soft_delete_restore(soft_delete_model: type[Any]) -> None:
    obj = soft_delete_model.objects.create(name="b")
    obj.delete()
    obj = soft_delete_model.all_objects.get(pk=obj.pk)
    obj.restore()
    assert soft_delete_model.objects.filter(pk=obj.pk).exists()


def test_queryset_delete_is_soft(soft_delete_model: type[Any]) -> None:
    soft_delete_model.objects.create(name="c")
    soft_delete_model.objects.create(name="d")
    soft_delete_model.objects.all().delete()
    assert soft_delete_model.objects.count() == 0
    assert soft_delete_model.all_objects.count() == 2


def test_hard_delete_removes_row(soft_delete_model: type[Any]) -> None:
    obj = soft_delete_model.objects.create(name="e")
    pk = obj.pk
    obj.hard_delete()
    assert not soft_delete_model.all_objects.filter(pk=pk).exists()
