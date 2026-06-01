"""Base models reused by every domain app, plus the core platform tables.

- ``TimeStampedModel`` / ``SoftDeleteModel`` are abstract bases.
- ``AuditEntry`` and ``SystemConfig`` are concrete platform tables that live in
  ``core`` (the leaf dependency every app may import).
"""

from __future__ import annotations

from django.conf import settings
from django.db import models

from .enums import SystemConfigType


class TimeStampedModel(models.Model):
    """Adds self-managing ``created_at`` / ``updated_at`` timestamps."""

    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class SoftDeleteQuerySet(models.QuerySet["SoftDeleteModel"]):
    """QuerySet whose ``delete()`` marks rows instead of removing them."""

    def delete(self) -> tuple[int, dict[str, int]]:  # type: ignore[override]
        from django.db.models.functions import Now

        count = super().update(deleted_at=Now())
        return count, {}

    def hard_delete(self) -> tuple[int, dict[str, int]]:
        return super().delete()

    def alive(self) -> SoftDeleteQuerySet:
        return self.filter(deleted_at__isnull=True)

    def dead(self) -> SoftDeleteQuerySet:
        return self.filter(deleted_at__isnull=False)


class SoftDeleteManager(models.Manager["SoftDeleteModel"]):
    """Default manager that hides soft-deleted rows."""

    def get_queryset(self) -> SoftDeleteQuerySet:
        return SoftDeleteQuerySet(self.model, using=self._db).filter(deleted_at__isnull=True)


class AllObjectsManager(models.Manager["SoftDeleteModel"]):
    """Escape hatch manager that includes soft-deleted rows."""

    def get_queryset(self) -> SoftDeleteQuerySet:
        return SoftDeleteQuerySet(self.model, using=self._db)


class SoftDeleteModel(TimeStampedModel):
    """Timestamped model with a nullable ``deleted_at`` soft-delete marker.

    ``objects`` excludes deleted rows; ``all_objects`` includes them.
    Instance ``delete()`` soft-deletes; ``hard_delete()`` removes the row.
    """

    deleted_at = models.DateTimeField(null=True, blank=True, default=None, db_index=True)

    objects = SoftDeleteManager()
    all_objects = AllObjectsManager()

    class Meta:
        abstract = True

    @property
    def is_deleted(self) -> bool:
        return self.deleted_at is not None

    def delete(  # type: ignore[override]
        self, using: str | None = None, keep_parents: bool = False
    ) -> None:
        from django.db.models.functions import Now

        self.deleted_at = Now()  # type: ignore[assignment]
        self.save(using=using, update_fields=["deleted_at", "updated_at"])
        self.refresh_from_db(fields=["deleted_at"])

    def hard_delete(
        self, using: str | None = None, keep_parents: bool = False
    ) -> tuple[int, dict[str, int]]:
        return super().delete(using=using, keep_parents=keep_parents)

    def restore(self) -> None:
        self.deleted_at = None
        self.save(update_fields=["deleted_at", "updated_at"])


class AuditEntry(TimeStampedModel):
    """A consequential end-user action on personal/sensitive data.

    Written exclusively through ``core.audit.audit()``. Action strings follow the
    ``domain.verb`` convention (``tenant.create``, ``rent.verify``).
    """

    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="audit_entries",
    )
    action = models.CharField(max_length=64, db_index=True)
    target_type = models.CharField(max_length=128, blank=True, default="")
    target_id = models.CharField(max_length=64, blank=True, default="")
    before = models.JSONField(null=True, blank=True, default=None)
    after = models.JSONField(null=True, blank=True, default=None)

    class Meta:
        verbose_name = "audit entry"
        verbose_name_plural = "audit entries"
        ordering = ("-created_at",)
        indexes = [models.Index(fields=["actor", "created_at"])]

    def __str__(self) -> str:
        return f"{self.action} by {self.actor_id or 'system'} @ {self.created_at:%Y-%m-%d %H:%M}"


class SystemConfig(TimeStampedModel):
    """Admin-tunable business value (Layer-3 config).

    Read through the cached ``core.config.get_config()`` accessor, which returns
    the value coerced to the Python type indicated by ``type``.
    """

    key = models.CharField(max_length=128, unique=True)
    value = models.TextField()
    type = models.CharField(max_length=8, choices=SystemConfigType.choices)
    description = models.CharField(max_length=255, blank=True, default="")
    effective_from = models.DateTimeField(null=True, blank=True, default=None)

    class Meta:
        verbose_name = "system config"
        verbose_name_plural = "system config"
        ordering = ("key",)

    def __str__(self) -> str:
        return f"{self.key}={self.value} ({self.type})"
