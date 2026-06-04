"""Seed system ``NotificationTemplate`` rows (EPIC-15.T-005).

Inserts the three auto-triggered system templates the platform relies on:

- ``rent_reminder_due`` — fired on ``rent_due``; nudges a tenant whose rent is
  past due. Delivered via WhatsApp + SMS. Bilingual.
- ``rent_receipt_generated`` — fired on ``payment_verified``; confirms a verified
  rent payment and links the receipt. Delivered via WhatsApp + SMS. Bilingual.
- ``welcome_new_user`` — fired on ``user_created``; greets a freshly registered
  user. Delivered in-app. Bilingual.

Each row carries the placeholder ``variables`` its body references so callers
(the notification sender) know which values to interpolate. Idempotent
(``update_or_create`` keyed on the unique ``key``) and reversible (reverse
removes exactly these three keys).
"""

from django.db import migrations

SYSTEM_TEMPLATES = [
    {
        "key": "rent_reminder_due",
        "trigger_event": "rent_due",
        "channels": ["whatsapp", "sms"],
        "title_en": "Rent payment reminder",
        "title_bn": "ভাড়া পরিশোধের অনুস্মারক",
        "body_en": (
            "Hi {tenant_name}, your rent of {amount} for {property_name} is due "
            "on {due_date}. Please pay using this link: {payment_link}"
        ),
        "body_bn": (
            "প্রিয় {tenant_name}, {property_name}-এর {amount} টাকা ভাড়া "
            "{due_date} তারিখে পরিশোধ করতে হবে। এই লিঙ্কে পরিশোধ করুন: {payment_link}"
        ),
        "variables": [
            "tenant_name",
            "amount",
            "property_name",
            "due_date",
            "payment_link",
        ],
    },
    {
        "key": "rent_receipt_generated",
        "trigger_event": "payment_verified",
        "channels": ["whatsapp", "sms"],
        "title_en": "Rent payment received",
        "title_bn": "ভাড়া পরিশোধ গৃহীত হয়েছে",
        "body_en": (
            "Thank you {tenant_name}. We received your rent of {amount} for "
            "{property_name} on {paid_date}. View your receipt: {receipt_link}"
        ),
        "body_bn": (
            "ধন্যবাদ {tenant_name}। {property_name}-এর {amount} টাকা ভাড়া "
            "{paid_date} তারিখে আমরা পেয়েছি। রসিদ দেখুন: {receipt_link}"
        ),
        "variables": [
            "tenant_name",
            "amount",
            "property_name",
            "paid_date",
            "receipt_link",
        ],
    },
    {
        "key": "welcome_new_user",
        "trigger_event": "user_created",
        "channels": ["inapp"],
        "title_en": "Welcome to Khatir",
        "title_bn": "খাতিরে স্বাগতম",
        "body_en": (
            "Welcome {user_name}! Your Khatir account is ready. Add your first "
            "property to start managing rent with ease."
        ),
        "body_bn": (
            "স্বাগতম {user_name}! আপনার খাতির অ্যাকাউন্ট প্রস্তুত। সহজে ভাড়া "
            "ব্যবস্থাপনা শুরু করতে আপনার প্রথম সম্পত্তি যোগ করুন।"
        ),
        "variables": ["user_name"],
    },
]

SEEDED_KEYS = [row["key"] for row in SYSTEM_TEMPLATES]


def seed_system_templates(apps, schema_editor):
    NotificationTemplate = apps.get_model("notifications", "NotificationTemplate")
    for row in SYSTEM_TEMPLATES:
        NotificationTemplate.objects.update_or_create(
            key=row["key"],
            defaults={
                "trigger_event": row["trigger_event"],
                "channels": row["channels"],
                "title_en": row["title_en"],
                "title_bn": row["title_bn"],
                "body_en": row["body_en"],
                "body_bn": row["body_bn"],
                "variables": row["variables"],
                "active": True,
            },
        )


def unseed_system_templates(apps, schema_editor):
    NotificationTemplate = apps.get_model("notifications", "NotificationTemplate")
    NotificationTemplate.objects.filter(key__in=SEEDED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("notifications", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(seed_system_templates, unseed_system_templates),
    ]
