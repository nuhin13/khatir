/// Properties-domain enums. Wire values are lowercase snake_case strings and
/// MUST match `docs/architecture/enums.md` (Area / UnitType / UnitStatus) and
/// the backend `properties/enums.py`. These are domain-specific (used only by
/// [Building] / [Unit]), so they live in the owning feature rather than
/// `core/enums`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

/// Dhaka zones — extensible via SystemConfig later. Mirrors backend `Area`.
@JsonEnum(valueField: 'wire')
enum Area {
  uttara('uttara'),
  mirpur('mirpur'),
  mohammadpur('mohammadpur'),
  dhanmondi('dhanmondi'),
  banasree('banasree'),
  gulshan('gulshan'),
  banani('banani'),
  bashundhara('bashundhara'),
  oldDhaka('old_dhaka'),
  other('other');

  const Area(this.wire);

  /// The lowercase snake_case value sent over the wire.
  final String wire;

  /// Parses a wire value into an [Area]. Returns `null` for unknown values.
  static Area? fromWire(String? value) {
    if (value == null) return null;
    for (final area in Area.values) {
      if (area.wire == value) return area;
    }
    return null;
  }
}

/// Kind of rentable unit. Mirrors backend `UnitType`.
@JsonEnum(valueField: 'wire')
enum UnitType {
  apartment('apartment'),
  room('room'),
  commercial('commercial'),
  garage('garage'),
  other('other');

  const UnitType(this.wire);

  /// The lowercase snake_case value sent over the wire.
  final String wire;

  /// Parses a wire value into a [UnitType]. Returns `null` for unknown values.
  static UnitType? fromWire(String? value) {
    if (value == null) return null;
    for (final type in UnitType.values) {
      if (type.wire == value) return type;
    }
    return null;
  }
}

/// Occupancy state of a unit. Mirrors backend `UnitStatus`.
@JsonEnum(valueField: 'wire')
enum UnitStatus {
  occupied('occupied'),
  vacant('vacant'),
  maintenance('maintenance');

  const UnitStatus(this.wire);

  /// The lowercase snake_case value sent over the wire.
  final String wire;

  /// Parses a wire value into a [UnitStatus]. Returns `null` for unknown values.
  static UnitStatus? fromWire(String? value) {
    if (value == null) return null;
    for (final status in UnitStatus.values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

/// Bulk-generate numbering scheme (request-time input, not persisted). Mirrors
/// backend `UnitScheme`.
@JsonEnum(valueField: 'wire')
enum UnitScheme {
  /// `1A, 1B, 2A …`
  letter('letter'),

  /// `101, 102, 201 …`
  number('number');

  const UnitScheme(this.wire);

  /// The lowercase snake_case value sent over the wire.
  final String wire;
}
