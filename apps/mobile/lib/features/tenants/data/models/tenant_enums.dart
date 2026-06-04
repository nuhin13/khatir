/// Tenants-domain enums. Wire values are lowercase snake_case strings and MUST
/// match `docs/architecture/enums.md` (VerificationStatus) and the backend
/// `tenants/enums.py`. Domain-specific (used only by [Tenant]), so they live in
/// the owning feature rather than `core/enums`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

/// EC/NID verification outcome for a tenant. Mirrors backend `VerificationStatus`.
@JsonEnum(valueField: 'wire')
enum VerificationStatus {
  unverified('unverified'),
  matched('matched'),
  notMatched('not_matched'),
  error('error');

  const VerificationStatus(this.wire);

  /// The lowercase snake_case value sent over the wire.
  final String wire;

  /// Parses a wire value into a [VerificationStatus]. Unknown/absent values
  /// degrade to [VerificationStatus.unverified] (the backend default) so a
  /// partial read never throws.
  static VerificationStatus fromWire(String? value) {
    if (value == null) return VerificationStatus.unverified;
    for (final status in VerificationStatus.values) {
      if (status.wire == value) return status;
    }
    return VerificationStatus.unverified;
  }
}
