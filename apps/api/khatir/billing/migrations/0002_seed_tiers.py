"""Seed the 6 default ``PricingTier`` rows (EPIC-10.T-002).

So the app has pricing data from day one. Keys mirror ``PricingTierKey`` in
``docs/architecture/enums.md`` (``free`` / ``per_tenant`` / ``bundle_20`` /
``bundle_40`` / ``unlimited_monthly`` / ``unlimited_annual``). Prices are
illustrative Bangladeshi-Taka defaults — the founder/admin tunes them live from
the admin portal (EPIC-12), so they are intentionally not authoritative here.

Idempotent (``update_or_create`` keyed on the unique ``key``) and reversible
(reverse removes exactly these 6 keys). Migrations never import app code so the
tier definitions stay frozen against future model/enum changes.
"""

from decimal import Decimal

from django.db import migrations

# Free tier: 0–2 tenants, ৳0, no NID verification.
# bundle_* and unlimited_* include verification + bundled credits.
# tenant_max = None means unlimited.
TIERS = [
    {
        "key": "free",
        "label": "Free",
        "label_bn": "বিনামূল্যে",
        "tenant_min": 0,
        "tenant_max": 2,
        "monthly_price": None,
        "annual_price": None,
        "includes_verification": False,
        "included_credits": 0,
        "active": True,
        "sort_order": 1,
    },
    {
        "key": "per_tenant",
        "label": "Per Tenant",
        "label_bn": "প্রতি ভাড়াটিয়া",
        "tenant_min": 3,
        "tenant_max": None,
        "monthly_price": Decimal("30.00"),
        "annual_price": Decimal("300.00"),
        "includes_verification": False,
        "included_credits": 0,
        "active": True,
        "sort_order": 2,
    },
    {
        "key": "bundle_20",
        "label": "Bundle 20",
        "label_bn": "বান্ডেল ২০",
        "tenant_min": 0,
        "tenant_max": 20,
        "monthly_price": Decimal("499.00"),
        "annual_price": Decimal("4990.00"),
        "includes_verification": True,
        "included_credits": 20,
        "active": True,
        "sort_order": 3,
    },
    {
        "key": "bundle_40",
        "label": "Bundle 40",
        "label_bn": "বান্ডেল ৪০",
        "tenant_min": 0,
        "tenant_max": 40,
        "monthly_price": Decimal("899.00"),
        "annual_price": Decimal("8990.00"),
        "includes_verification": True,
        "included_credits": 40,
        "active": True,
        "sort_order": 4,
    },
    {
        "key": "unlimited_monthly",
        "label": "Unlimited (Monthly)",
        "label_bn": "আনলিমিটেড (মাসিক)",
        "tenant_min": 0,
        "tenant_max": None,
        "monthly_price": Decimal("1499.00"),
        "annual_price": None,
        "includes_verification": True,
        "included_credits": 100,
        "active": True,
        "sort_order": 5,
    },
    {
        "key": "unlimited_annual",
        "label": "Unlimited (Annual)",
        "label_bn": "আনলিমিটেড (বার্ষিক)",
        "tenant_min": 0,
        "tenant_max": None,
        "monthly_price": None,
        "annual_price": Decimal("14990.00"),
        "includes_verification": True,
        "included_credits": 100,
        "active": True,
        "sort_order": 6,
    },
]

SEEDED_KEYS = [tier["key"] for tier in TIERS]


def seed_tiers(apps, schema_editor):
    PricingTier = apps.get_model("billing", "PricingTier")
    for tier in TIERS:
        PricingTier.objects.update_or_create(
            key=tier["key"],
            defaults={k: v for k, v in tier.items() if k != "key"},
        )


def unseed_tiers(apps, schema_editor):
    PricingTier = apps.get_model("billing", "PricingTier")
    PricingTier.objects.filter(key__in=SEEDED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("billing", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(seed_tiers, unseed_tiers),
    ]
