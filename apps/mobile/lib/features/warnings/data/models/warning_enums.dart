/// Warnings-domain enums. Wire values are lowercase snake_case strings and MUST
/// match `docs/architecture/enums.md` and the backend `warnings/enums.py`.
/// Domain-specific (used only by [Warning]), so they live in the owning feature.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

/// The type of a private warning notice. Mirrors backend `WarningType`.
///
/// All values are private to the landlord–tenant relationship; none are
/// publicly visible or shared across landlords.
@JsonEnum(valueField: 'wire')
enum WarningType {
  lateRent('late_rent'),
  leaseViolation('lease_violation'),
  noise('noise'),
  propertyDamage('property_damage'),
  other('other');

  const WarningType(this.wire);

  /// The lowercase snake_case value sent over the wire.
  final String wire;

  /// Parses a wire value into a [WarningType]. Unknown/absent values degrade to
  /// [WarningType.other] so a partial read never throws.
  static WarningType fromWire(String? value) {
    if (value == null) return WarningType.other;
    for (final type in WarningType.values) {
      if (type.wire == value) return type;
    }
    return WarningType.other;
  }
}
