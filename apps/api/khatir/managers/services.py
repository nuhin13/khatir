"""Manager owner-link service layer (EPIC-22 · T-003 §2).

The business rules for the manager↔owner consent lifecycle live here so the
views stay thin (``04_coding_conventions.md`` §6):

- :func:`request_owner_link` — a manager requests access to an owner. A
  ``pending`` :class:`ManagerOwnerLink` is created and the owner is notified
  (via EPIC-15) so they can grant consent. Audited.
- :func:`respond_to_link` — the owner accepts or declines a pending request. On
  *accept* a :class:`~khatir.compliance.models.ConsentRecord` is written and the
  link becomes ``active`` (only then does the manager gain ``for_user`` access);
  on *decline* the link is ``revoked``. Both outcomes are audited.

Notifications go through EPIC-15's :func:`compose_notification` with a
``specific`` (single-user) audience, so the owner gets the request on their
in-app channel without coupling the manager domain to delivery details.
"""

from __future__ import annotations

import logging

from django.db import IntegrityError, transaction
from django.utils import timezone

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.compliance.enums import ConsentType
from khatir.compliance.models import ConsentRecord
from khatir.core.audit import audit
from khatir.core.enums import Channel
from khatir.core.exceptions import ConflictError, ValidationError
from khatir.notifications.enums import NotificationAudienceType
from khatir.notifications.services import compose_notification

from .enums import ManagerOwnerLinkStatus
from .models import ManagerOwnerLink

logger = logging.getLogger(__name__)


def _notify_owner_of_request(link: ManagerOwnerLink) -> None:
    """Notify the owner (EPIC-15) that a manager requested to manage them.

    A best-effort, single-recipient in-app notification. Sent on commit by
    EPIC-15's compose pipeline; failures to *compose* surface as that pipeline's
    errors, but a successful link request never depends on delivery.
    """
    manager_name = link.manager.name or link.manager.phone or "A manager"
    compose_notification(
        admin_user=None,
        audience_type=NotificationAudienceType.SPECIFIC,
        audience_filter={"user_ids": [link.owner_id]},
        channels=[Channel.INAPP],
        content={
            "title_en": "Manager access request",
            "title_bn": "ম্যানেজার অ্যাক্সেস অনুরোধ",
            "body_en": (
                f"{manager_name} has requested to manage your properties. "
                "Open Khatir to accept or decline."
            ),
            "body_bn": (
                f"{manager_name} আপনার সম্পত্তি পরিচালনার অনুরোধ করেছেন। "
                "গ্রহণ বা প্রত্যাখ্যান করতে খাতির খুলুন।"
            ),
        },
    )


def request_owner_link(
    *,
    manager: User,
    owner: User,
    permissions_scope: list[str] | None = None,
) -> ManagerOwnerLink:
    """Manager requests a link to ``owner``; owner is notified for consent.

    Creates a ``pending`` link (inactive until the owner consents). Raises
    :class:`ValidationError` if ``owner`` is not a landlord or the manager
    targets themselves, and :class:`ConflictError` if a link to that owner
    already exists (the unique ``(manager, owner)`` constraint).
    """
    if owner.pk == manager.pk:
        raise ValidationError("A manager cannot link to themselves.")
    if owner.role != Role.LANDLORD:
        raise ValidationError("Owner must be a landlord.")

    scope = list(permissions_scope or [])

    try:
        with transaction.atomic():
            link = ManagerOwnerLink.objects.create(
                manager=manager,
                owner=owner,
                status=ManagerOwnerLinkStatus.PENDING,
                permissions_scope=scope,
            )
            audit(
                actor=manager,
                action="manager.owner_link.request",
                target=link,
                before=None,
                after={
                    "owner_id": owner.pk,
                    "status": link.status,
                    "permissions_scope": scope,
                },
            )
    except IntegrityError as exc:
        raise ConflictError(
            "A link to this owner already exists."
        ) from exc

    _notify_owner_of_request(link)
    logger.info(
        "manager #%s requested owner link to #%s (link #%s)",
        manager.pk,
        owner.pk,
        link.pk,
    )
    return link


def respond_to_link(
    *,
    owner: User,
    link: ManagerOwnerLink,
    accept: bool,
) -> ManagerOwnerLink:
    """Owner accepts or declines a *pending* link request.

    ``accept`` activates the link and records the owner's PDPA data-sharing
    consent (``ConsentRecord``); declining revokes it. Only the link's own owner
    may respond, and only while the link is ``pending`` — re-responding to a
    settled link raises :class:`ConflictError`.
    """
    if link.owner_id != owner.pk:
        # Surface as not-actionable rather than leaking existence detail; the
        # view layer scopes the lookup, so this is a defensive guard.
        raise ValidationError("This request does not belong to you.")
    if link.status != ManagerOwnerLinkStatus.PENDING:
        raise ConflictError(
            f"This request is already {link.status} and cannot be changed."
        )

    before = {"status": link.status, "consent_record_id": link.consent_record_id}

    with transaction.atomic():
        if accept:
            consent = ConsentRecord.objects.create(
                user=owner,
                consent_type=ConsentType.PDPA_DATA_SHARING,
                granted_at=timezone.now(),
            )
            link.status = ManagerOwnerLinkStatus.ACTIVE
            link.consent_record = consent
            link.save(update_fields=["status", "consent_record", "updated_at"])
            action = "manager.owner_link.accept"
        else:
            link.status = ManagerOwnerLinkStatus.REVOKED
            link.save(update_fields=["status", "updated_at"])
            action = "manager.owner_link.decline"

        audit(
            actor=owner,
            action=action,
            target=link,
            before=before,
            after={
                "status": link.status,
                "consent_record_id": link.consent_record_id,
            },
        )

    logger.info(
        "owner #%s %s link #%s (manager #%s)",
        owner.pk,
        "accepted" if accept else "declined",
        link.pk,
        link.manager_id,
    )
    return link
