from django.apps import AppConfig


class CoreConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "khatir.core"

    def ready(self) -> None:
        # Register the SystemConfig cache-invalidation signal receivers.
        from . import config  # noqa: F401
