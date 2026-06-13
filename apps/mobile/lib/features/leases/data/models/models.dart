import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../tenants/data/models/tenant_enums.dart';
import 'lease_enums.dart';

part 'models.freezed.dart';

/// A persisted lease, mirroring the backend `LeaseSerializer`
/// (`{id, unit_id, tenant_id, landlord_id, start_date, end_date, rent, advance,
/// status, signed_pdf_ref, created_at, updated_at}`).
///
/// The FK ids ([unitId], [tenantId], [landlordId]) and [status] are read-only
/// server-side; the client never sets them. Monetary fields ([rent], [advance])
/// arrive as DRF `DecimalField` **strings** and are parsed to [double]. Unknown
/// keys are ignored; nullable timestamps tolerate absent values.
@freezed
abstract class Lease with _$Lease {
  const factory Lease({
    required String id,
    @Default('') String unitId,
    @Default('') String tenantId,
    @Default('') String landlordId,
    DateTime? startDate,
    DateTime? endDate,
    @Default(0) double rent,
    @Default(0) double advance,
    @Default(LeaseStatus.draft) LeaseStatus status,
    @Default('') String signedPdfRef,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Lease;

  /// Parses a lease payload. Money strings tolerate null; `status` degrades to
  /// `draft`; timestamps/dates tolerate null.
  static Lease fromJson(Map<String, dynamic> json) => Lease(
        id: json['id']?.toString() ?? '',
        unitId: json['unit_id']?.toString() ?? '',
        tenantId: json['tenant_id']?.toString() ?? '',
        landlordId: json['landlord_id']?.toString() ?? '',
        startDate: _toDate(json['start_date']),
        endDate: _toDate(json['end_date']),
        rent: _toDouble(json['rent']),
        advance: _toDouble(json['advance']),
        status: LeaseStatus.fromWire(json['status'] as String?),
        signedPdfRef: json['signed_pdf_ref'] as String? ?? '',
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );
}

/// A single rent-schedule row (one billing period), mirroring the backend
/// `RentScheduleSerializer` (`{id, lease_id, period, due_day, due_date, amount,
/// status, sent_at, created_at, updated_at}`).
///
/// Read-only client-side — the schedule is materialised by the generation job
/// on the server, not by the client. [period] is the `YYYY-MM` billing month;
/// [amount] arrives as a DRF `DecimalField` string and is parsed to [double].
@freezed
abstract class RentSchedule with _$RentSchedule {
  const factory RentSchedule({
    required String id,
    @Default('') String leaseId,
    @Default('') String period,
    @Default(0) int dueDay,
    DateTime? dueDate,
    @Default(0) double amount,
    @Default(RentScheduleStatus.pending) RentScheduleStatus status,
    DateTime? sentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _RentSchedule;

  /// Parses a rent-schedule row. `amount` string tolerates null; `status`
  /// degrades to `pending`; timestamps/dates tolerate null.
  static RentSchedule fromJson(Map<String, dynamic> json) => RentSchedule(
        id: json['id']?.toString() ?? '',
        leaseId: json['lease_id']?.toString() ?? '',
        period: json['period'] as String? ?? '',
        dueDay: _toInt(json['due_day']),
        dueDate: _toDate(json['due_date']),
        amount: _toDouble(json['amount']),
        status: RentScheduleStatus.fromWire(json['status'] as String?),
        sentAt: _toDate(json['sent_at']),
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );
}

/// The compact tenant summary embedded in a unit's current-lease payload,
/// mirroring the backend `LeaseTenantSummarySerializer`
/// (`{id, name, nid_number_masked, verification_status}`).
///
/// Just enough to label the lease on the unit-detail screen — the full masked
/// tenant record is fetched from the tenants endpoints. The full NID is never
/// exposed; only [nidNumberMasked].
@freezed
abstract class LeaseTenantSummary with _$LeaseTenantSummary {
  const factory LeaseTenantSummary({
    required String id,
    @Default('') String name,
    @Default('') String nidNumberMasked,
    @Default(VerificationStatus.unverified)
    VerificationStatus verificationStatus,
  }) = _LeaseTenantSummary;

  /// Parses an embedded tenant summary. Tolerates a missing object by being
  /// called only when present (see [UnitLease.fromJson]).
  static LeaseTenantSummary fromJson(Map<String, dynamic> json) =>
      LeaseTenantSummary(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        nidNumberMasked: json['nid_number_masked'] as String? ?? '',
        verificationStatus:
            VerificationStatus.fromWire(json['verification_status'] as String?),
      );
}

/// A unit's current (active) lease plus an embedded [tenant] summary, mirroring
/// the backend `UnitLeaseSerializer` (the `LeaseSerializer` fields + a nested
/// `tenant`). Returned by `GET /units/{id}/lease`.
@freezed
abstract class UnitLease with _$UnitLease {
  const factory UnitLease({
    required Lease lease,
    LeaseTenantSummary? tenant,
  }) = _UnitLease;

  /// Parses a unit-lease payload: the lease fields live at the top level with a
  /// nested `tenant` object (null when the server omits it).
  static UnitLease fromJson(Map<String, dynamic> json) => UnitLease(
        lease: Lease.fromJson(json),
        tenant: json['tenant'] is Map<String, dynamic>
            ? LeaseTenantSummary.fromJson(json['tenant'] as Map<String, dynamic>)
            : null,
      );
}

double _toDouble(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

DateTime? _toDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
