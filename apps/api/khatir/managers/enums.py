"""Manager-domain enums (EPIC-22, B2B Manager).

Domain-specific — used only by the ``managers`` app — so they live in the
owning app rather than ``khatir.core.enums``. Wire values are the single source
of truth in ``docs/architecture/enums.md``: lowercase snake_case strings, never
integers on the wire.
"""

from django.db import models


class ManagerOwnerLinkStatus(models.TextChoices):
    """Lifecycle of a manager-to-owner link.

    A link starts ``pending`` (manager requested access, owner has not yet
    consented), becomes ``active`` once the owner grants consent, and moves to
    ``revoked`` when either party withdraws. Only ``active`` links grant the
    manager ``for_user`` access to the owner's data.
    """

    PENDING = "pending", "Pending"
    ACTIVE = "active", "Active"
    REVOKED = "revoked", "Revoked"


class ManagerTeamMemberRole(models.TextChoices):
    """What a team member is inside a manager's organisation.

    A ``staff`` member performs day-to-day work scoped by ``permissions_scope``.
    A ``sub_manager`` is a delegate with broader authority under the manager.
    """

    STAFF = "staff", "Staff"
    SUB_MANAGER = "sub_manager", "Sub-manager"


class ManagerTeamMemberStatus(models.TextChoices):
    """Lifecycle of a team-member seat.

    A seat is ``active`` while the member may act, and ``revoked`` once their
    access is withdrawn.
    """

    ACTIVE = "active", "Active"
    REVOKED = "revoked", "Revoked"
