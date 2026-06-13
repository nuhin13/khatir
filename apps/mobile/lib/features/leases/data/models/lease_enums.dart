/// Leases-domain enums. Wire values are lowercase snake_case strings and MUST
/// match `docs/architecture/enums.md` (LeaseStatus / RentScheduleStatus) and
/// the backend `leases/enums.py`. Domain-specific (used only by [Lease] /
/// [RentSchedule]), so they live in the owning feature rather than `core/enums`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

/// Lifecycle of a lease. Mirrors backend `LeaseStatus`.
///
/// A lease is created as a [draft]; activation moves it to [active] (and
/// materialises its rent schedule). It closes as either [ended] (natural
/// end-of-term) or [terminated] (early/forced close).
@JsonEnum(valueField: 'wire')
enum LeaseStatus {
  draft('draft'),
  active('active'),
  ended('ended'),
  terminated('terminated');

  const LeaseStatus(this.wire);

  /// The lowercase snake_case value sent over the wire.
  final String wire;

  /// Parses a wire value into a [LeaseStatus]. Unknown/absent values degrade to
  /// [LeaseStatus.draft] (the backend default for a new lease) so a partial
  /// read never throws.
  static LeaseStatus fromWire(String? value) {
    if (value == null) return LeaseStatus.draft;
    for (final status in LeaseStatus.values) {
      if (status.wire == value) return status;
    }
    return LeaseStatus.draft;
  }
}

/// Lifecycle of a single rent-schedule row (one billing period). Mirrors
/// backend `RentScheduleStatus`.
///
/// A period starts [pending], becomes [requested] when a rent request is sent,
/// [paid] once the proof is verified, and [overdue] when the due date passes
/// unpaid.
@JsonEnum(valueField: 'wire')
enum RentScheduleStatus {
  pending('pending'),
  requested('requested'),
  paid('paid'),
  overdue('overdue');

  const RentScheduleStatus(this.wire);

  /// The lowercase snake_case value sent over the wire.
  final String wire;

  /// Parses a wire value into a [RentScheduleStatus]. Unknown/absent values
  /// degrade to [RentScheduleStatus.pending] (a period's initial state) so a
  /// partial read never throws.
  static RentScheduleStatus fromWire(String? value) {
    if (value == null) return RentScheduleStatus.pending;
    for (final status in RentScheduleStatus.values) {
      if (status.wire == value) return status;
    }
    return RentScheduleStatus.pending;
  }
}
