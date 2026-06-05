"""Manager-domain models (EPIC-22, B2B Manager).

``ManagerOwnerLink`` connects a *manager* (``Role.MANAGER``) to a property
*owner* (``Role.LANDLORD``) they are allowed to manage. The link is formalized
with an explicit consent + status lifecycle:

- ``pending``  — manager requested access; owner has not consented yet.
- ``active``   — owner granted consent (``consent_record`` set); the manager may
  act for this owner. **Only active links grant ``for_user`` access.**
- ``revoked``  — access withdrawn.

``permissions_scope`` is a JSON list of what the manager may do for this owner
(e.g. ``["view_reports", "collect_rent"]``).
"""

from __future__ import annotations

from django.conf import settings
from django.db import models

from khatir.core.models import TimeStampedModel

from .enums import ManagerOwnerLinkStatus


class ManagerOwnerLinkQuerySet(models.QuerySet["ManagerOwnerLink"]):
    """Scoping helpers for manager-to-owner links."""

    def active(self) -> ManagerOwnerLinkQuerySet:
        """Only links the owner has consented to and not revoked."""
        return self.filter(status=ManagerOwnerLinkStatus.ACTIVE)

    def for_manager(self, manager: object) -> ManagerOwnerLinkQuerySet:
        """Links belonging to ``manager`` (regardless of status)."""
        manager_id = getattr(manager, "pk", None)
        if manager_id is None:
            return self.none()
        return self.filter(manager_id=manager_id)

    def active_owner_ids_for(self, manager: object) -> list[int]:
        """Owner PKs this manager may currently act for (active links only).

        This is the single source of truth for the EPIC-03 ``for_user`` scope:
        a manager's accessible owners are exactly those with an **active** link.
        """
        return list(
            self.for_manager(manager).active().values_list("owner_id", flat=True)
        )


class ManagerOwnerLink(TimeStampedModel):
    """A manager's authorization to act for a property owner.

    Uniqueness is enforced per ``(manager, owner)`` pair so a manager cannot
    hold two links to the same owner.
    """

    manager = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="managed_owner_links",
        help_text="The managing user (role = manager).",
    )
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="manager_links",
        help_text="The property owner being managed (role = landlord).",
    )
    status = models.CharField(
        max_length=16,
        choices=ManagerOwnerLinkStatus.choices,
        default=ManagerOwnerLinkStatus.PENDING,
        db_index=True,
        help_text="Lifecycle: pending → active (owner consented) → revoked.",
    )
    consent_record = models.ForeignKey(
        "compliance.ConsentRecord",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        default=None,
        related_name="manager_owner_links",
        help_text="The owner's consent event that activated this link, if any.",
    )
    permissions_scope = models.JSONField(
        default=list,
        blank=True,
        help_text="List of actions this manager may perform for this owner.",
    )

    objects = ManagerOwnerLinkQuerySet.as_manager()

    class Meta:
        verbose_name = "manager-owner link"
        verbose_name_plural = "manager-owner links"
        ordering = ("-created_at",)
        constraints = [
            models.UniqueConstraint(
                fields=["manager", "owner"],
                name="uniq_manager_owner_link",
            ),
        ]
        indexes = [
            models.Index(fields=["manager", "status"]),
            models.Index(fields=["owner", "status"]),
        ]

    def __str__(self) -> str:
        return f"{self.manager_id} → {self.owner_id} ({self.status})"

    @property
    def is_active(self) -> bool:
        return self.status == ManagerOwnerLinkStatus.ACTIVE
