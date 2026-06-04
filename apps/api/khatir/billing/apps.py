from django.apps import AppConfig


class BillingConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "khatir.billing"

    def ready(self) -> None:
        # Register the PricingTier cache-invalidation signal receivers.
        from . import signals  # noqa: F401
