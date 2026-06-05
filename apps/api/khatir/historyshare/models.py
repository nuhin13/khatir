"""History-sharing domain models — EPIC-24 (tenant-controlled rental history).

A ``HistoryShare`` is created **by the tenant** to share their FACTUAL rental
history with a prospective ``recipient_landlord``. There is deliberately **no
landlord-initiated lookup** path: a landlord can never pull a tenant's history;
the tenant must originate and consent to every share.

Built defensively, per the EPIC-24 charter:

* **Tenant-controlled** — the share carries a ``tenant`` FK and is created on the
  tenant's action only.
* **Consent-per-share** — every share links a ``consent_record`` (EPIC-16) that
  logs the tenant's explicit, time-stamped consent for *this* share.
* **Factual-only** — at share time we snapshot a FACTUAL stats blob
  (``on_time_payment_count``, ``total_payments``, ``lease_completed``) computed
  by :func:`compute_factual_stats`. There is **no subjective field** — no
  rating, no score, no free-text landlord opinion — anywhere in this model.
* **Expirable + revocable** — ``expires_at`` bounds the share's lifetime and
  ``revoked_at`` lets the tenant kill it early. :meth:`HistoryShare.is_active`
  enforces both at read time.

The stats are stored as a JSON snapshot rather than recomputed on read so that
revoking access or changing later payment data never retroactively alters what a
recipient already saw — and so a read endpoint never has to touch the tenant's
live rent records.
"""

from __future__ import annotations

from django.conf import settings
from django.db import models
from django.utils import timezone

from khatir.core.models import TimeStampedModel

from .stats import FactualStats, compute_factual_stats

__all__ = ["HistoryShare", "FactualStats", "compute_factual_stats"]


class HistoryShare(TimeStampedModel):
    """A tenant-initiated, consent-gated, factual-only share of rental history.

    Subjective data is structurally impossible here: the only payload is the
    ``scope`` selector and the ``factual_stats`` snapshot, both of which carry
    counts/booleans only.
    """

    tenant = models.ForeignKey(
        "tenants.Tenant",
        on_delete=models.PROTECT,
        related_name="history_shares",
        help_text="The tenant who owns and initiated this share. PROTECT — "
        "sharing history is tenant-controlled and the record is auditable.",
    )
    recipient_landlord = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="received_history_shares",
        help_text="The prospective landlord the tenant chose to share with. "
        "A landlord can NEVER initiate this — the tenant always originates.",
    )
    scope = models.JSONField(
        default=dict,
        blank=True,
        help_text="Tenant-selected scope of what to share (e.g. which leases / "
        "date range). Selector only — never holds subjective data.",
    )
    consent_record = models.ForeignKey(
        "compliance.ConsentRecord",
        on_delete=models.PROTECT,
        related_name="history_shares",
        help_text="The explicit, time-stamped consent logged for THIS share "
        "(EPIC-16). PROTECT — consent is append-only and must never be lost.",
    )
    factual_stats = models.JSONField(
        default=dict,
        blank=True,
        help_text="FACTUAL stats snapshot computed at share time "
        "(on_time_payment_count, total_payments, lease_completed). "
        "Counts/booleans only — NO subjective field, ever.",
    )
    expires_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="When this share stops being readable. Null = no expiry.",
    )
    revoked_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="When the tenant revoked this share. Null = still live.",
    )

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["tenant"]),
            models.Index(fields=["recipient_landlord"]),
        ]

    def __str__(self) -> str:
        return (
            f"HistoryShare #{self.pk} · tenant {self.tenant_id} "
            f"→ landlord {self.recipient_landlord_id}"
        )

    def is_active(self, *, now: timezone.datetime | None = None) -> bool:
        """True only if the share is neither revoked nor expired.

        Consent/expiry/revoke enforcement on the read path relies on this.
        """
        moment = now or timezone.now()
        if self.revoked_at is not None:
            return False
        if self.expires_at is not None and self.expires_at <= moment:
            return False
        return True
