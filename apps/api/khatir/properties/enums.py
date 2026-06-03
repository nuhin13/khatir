"""Properties-domain enums — Domain 2 of ``06_database_schema.md``.

These are domain-specific (used only by ``Building`` / ``Unit``) and therefore
live in the owning app rather than ``khatir.core.enums``. The wire values are
the single source of truth in ``docs/architecture/enums.md`` — lowercase
snake_case strings, never integers on the wire.
"""

from django.db import models


class Area(models.TextChoices):
    """Dhaka zones — extensible via SystemConfig later."""

    UTTARA = "uttara", "Uttara"
    MIRPUR = "mirpur", "Mirpur"
    MOHAMMADPUR = "mohammadpur", "Mohammadpur"
    DHANMONDI = "dhanmondi", "Dhanmondi"
    BANASREE = "banasree", "Banasree"
    GULSHAN = "gulshan", "Gulshan"
    BANANI = "banani", "Banani"
    BASHUNDHARA = "bashundhara", "Bashundhara"
    OLD_DHAKA = "old_dhaka", "Old Dhaka"
    OTHER = "other", "Other"


class UnitType(models.TextChoices):
    APARTMENT = "apartment", "Apartment"
    ROOM = "room", "Room"
    COMMERCIAL = "commercial", "Commercial"
    GARAGE = "garage", "Garage"
    OTHER = "other", "Other"


class UnitStatus(models.TextChoices):
    OCCUPIED = "occupied", "Occupied"
    VACANT = "vacant", "Vacant"
    MAINTENANCE = "maintenance", "Maintenance"
