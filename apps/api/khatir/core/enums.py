"""Cross-app enums.

Single source of truth mirrored from ``docs/architecture/enums.md``. Only the
enums that are genuinely cross-app live here; domain-specific enums belong in
their owning app's ``enums.py``. Wire values are lowercase snake_case strings —
never integers on the wire.
"""

from django.db import models


class Role(models.TextChoices):
    LANDLORD = "landlord", "Landlord"
    MANAGER = "manager", "Manager"
    TENANT = "tenant", "Tenant"
    CARETAKER = "caretaker", "Caretaker"
    ADMIN = "admin", "Admin"


class AdminRole(models.TextChoices):
    SUPER = "super", "Super"
    OPS = "ops", "Ops"
    FINANCE = "finance", "Finance"
    COMPLIANCE = "compliance", "Compliance"
    SUPPORT = "support", "Support"


class Language(models.TextChoices):
    BN = "bn", "Bangla"
    EN = "en", "English"


class Channel(models.TextChoices):
    INAPP = "inapp", "In-app"
    WHATSAPP = "whatsapp", "WhatsApp"
    SMS = "sms", "SMS"
    EMAIL = "email", "Email"


class SystemConfigType(models.TextChoices):
    INT = "int", "Integer"
    MONEY = "money", "Money"
    TEXT = "text", "Text"
    BOOL = "bool", "Boolean"


class ErrorCode(models.TextChoices):
    """API error-envelope codes (canonical, see ``04_coding_conventions.md`` §1)."""

    VALIDATION_ERROR = "validation_error", "Validation error"
    NOT_FOUND = "not_found", "Not found"
    PERMISSION_DENIED = "permission_denied", "Permission denied"
    AUTH_REQUIRED = "auth_required", "Authentication required"
    AUTH_INVALID = "auth_invalid", "Authentication invalid"
    CONFLICT = "conflict", "Conflict"
    RATE_LIMITED = "rate_limited", "Rate limited"
    UPSTREAM_UNAVAILABLE = "upstream_unavailable", "Upstream unavailable"
    FEATURE_DISABLED = "feature_disabled", "Feature disabled"
    PAYMENT_REQUIRED = "payment_required", "Payment required"
    SERVER_ERROR = "server_error", "Server error"
