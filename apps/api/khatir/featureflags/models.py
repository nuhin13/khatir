"""Feature-flags domain models — Domain 8 of ``06_database_schema.md``.

``FeatureFlag`` provides an admin-editable on/off switch (with an optional
JSON payload) for any product feature. Its ``scope`` controls whether the flag
applies globally, per role, or per user.

``KillSwitchEvent`` is an **append-only** audit log of emergency kill-switch
activations. It is never edited or deleted — the save signal blocks updates
and the admin marks it read-only.
"""

from __future__ import annotations

from django.db import models

from khatir.core.models import TimeStampedModel

from .enums import FlagScope, KillSwitchAction


class FeatureFlag(TimeStampedModel):
    """An admin-editable feature toggle with an optional JSON payload.

    ``key`` is the stable code identifier (e.g. ``"nid_ocr_enabled"``).
    ``scope`` selects whether the flag applies to everyone (global), a
    subset of roles, or a specific user. ``value_json`` carries arbitrary
    config data (thresholds, provider keys, …) when a bool is insufficient.

    ``updated_by`` records **which admin** last changed this flag; it is
    nullable so the first auto-created row (e.g. via data migration) is
    valid without a staff account.
    """

    key = models.CharField(
        max_length=128,
        unique=True,
        db_index=True,
        help_text="Stable code identifier, e.g. 'nid_ocr_enabled'.",
    )
    description = models.TextField(
        blank=True,
        default="",
        help_text="Human-readable explanation of what this flag controls.",
    )
    scope = models.CharField(
        max_length=8,
        choices=FlagScope.choices,
        default=FlagScope.GLOBAL,
        db_index=True,
        help_text="global / role / user.",
    )
    enabled = models.BooleanField(
        default=False,
        db_index=True,
        help_text="Master on/off switch.",
    )
    value_json = models.JSONField(
        null=True,
        blank=True,
        default=None,
        help_text="Optional JSON payload (thresholds, provider config, …). None = no extra config.",
    )
    updated_by = models.ForeignKey(
        "admin_portal.AdminUser",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        default=None,
        related_name="updated_flags",
        help_text="The admin who last changed this flag.",
    )

    class Meta:
        verbose_name = "feature flag"
        verbose_name_plural = "feature flags"
        ordering = ("key",)
        indexes = [
            models.Index(fields=["scope", "enabled"]),
        ]

    def __str__(self) -> str:
        state = "on" if self.enabled else "off"
        return f"{self.key} [{self.scope}] {state}"


class KillSwitchEvent(models.Model):
    """An immutable log entry for every kill-switch activation/deactivation.

    This model is **append-only** — neither the app code nor the admin UI
    ever edits or deletes a row. ``created_at`` is set once at insert
    (``auto_now_add``). ``updated_at`` is deliberately omitted: there is no
    valid reason to track when an immutable row was "last modified".

    ``admin_user`` is nullable so that a programmatic emergency shutdown
    (triggered by a health-check, not a human) can still be recorded.
    """

    switch_key = models.CharField(
        max_length=128,
        db_index=True,
        help_text="Identifies which kill-switch was toggled, e.g. 'payment_gateway'.",
    )
    action = models.CharField(
        max_length=8,
        choices=KillSwitchAction.choices,
        db_index=True,
        help_text="disable / enable.",
    )
    reason = models.TextField(
        help_text="Why this switch was thrown. Required for audit compliance.",
    )
    admin_user = models.ForeignKey(
        "admin_portal.AdminUser",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        default=None,
        related_name="killswitch_events",
        help_text="The admin who triggered this event; null for automated triggers.",
    )
    lawyer_reference = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="Optional legal/ticket reference (e.g. Jira ticket, counsel email).",
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True,
        help_text="Timestamp of the event — set once at creation, never changed.",
    )

    class Meta:
        verbose_name = "kill-switch event"
        verbose_name_plural = "kill-switch events"
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["switch_key", "created_at"]),
        ]

    def __str__(self) -> str:
        return f"{self.switch_key} {self.action} @ {self.created_at:%Y-%m-%d %H:%M}"

    def save(self, *args: object, **kwargs: object) -> None:
        """Block any update — KillSwitchEvent rows are append-only."""
        if self.pk is not None:
            raise TypeError(
                "KillSwitchEvent is immutable — create a new row instead of updating."
            )
        super().save(*args, **kwargs)

    def delete(self, *args: object, **kwargs: object) -> tuple[int, dict[str, int]]:  # type: ignore[override]
        """Block deletion — kill-switch events must be preserved for audit."""
        raise TypeError(
            "KillSwitchEvent rows cannot be deleted — they are an immutable audit log."
        )
