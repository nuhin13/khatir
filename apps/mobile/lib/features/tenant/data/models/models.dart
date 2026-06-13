import 'package:freezed_annotation/freezed_annotation.dart';

import 'tenant_enums.dart';

part 'models.freezed.dart';

// ── TenantLease ────────────────────────────────────────────────────────────

/// The authenticated tenant's current (active) lease, returned by
/// `GET /api/v1/me/lease`.
///
/// All FK ids and server-generated fields are read-only client-side.
/// [monthlyRent] comes back as a DRF `DecimalField` string and is parsed to
/// [double]. [leaseDocumentRef] is null when no AI lease PDF has been
/// generated (EPIC-18).
@freezed
abstract class TenantLease with _$TenantLease {
  const factory TenantLease({
    required String id,
    @Default('') String unitId,
    @Default('') String unitLabel,
    @Default('') String buildingLabel,
    @Default('') String landlordName,
    @Default('') String landlordPhone,
    @Default(0) double monthlyRent,
    @Default(0) double advanceAmount,
    DateTime? startDate,
    DateTime? endDate,
    @Default('') String noticePeriod,
    @Default('') String terms,
    String? leaseDocumentRef,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TenantLease;

  static TenantLease fromJson(Map<String, dynamic> json) => TenantLease(
        id: json['id']?.toString() ?? '',
        unitId: json['unit_id']?.toString() ?? '',
        unitLabel: json['unit_label'] as String? ?? '',
        buildingLabel: json['building_label'] as String? ?? '',
        landlordName: json['landlord_name'] as String? ?? '',
        landlordPhone: json['landlord_phone'] as String? ?? '',
        monthlyRent: _toDouble(json['monthly_rent']),
        advanceAmount: _toDouble(json['advance_amount']),
        startDate: _toDate(json['start_date']),
        endDate: _toDate(json['end_date']),
        noticePeriod: json['notice_period'] as String? ?? '',
        terms: json['terms'] as String? ?? '',
        leaseDocumentRef: json['lease_document_ref'] as String?,
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );
}

// ── TenantRent ─────────────────────────────────────────────────────────────

/// The authenticated tenant's current-month rent status, returned by
/// `GET /api/v1/me/rent`.
///
/// [status] is the rent payment status for the current billing period.
/// [amountDue] is 0 when the rent is paid. [dueDate] is null when paid.
@freezed
abstract class TenantRent with _$TenantRent {
  const factory TenantRent({
    required String id,
    @Default('') String period,
    @Default(RentStatus.due) RentStatus status,
    @Default(0) double amountDue,
    @Default(0) double amountPaid,
    DateTime? dueDate,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TenantRent;

  static TenantRent fromJson(Map<String, dynamic> json) => TenantRent(
        id: json['id']?.toString() ?? '',
        period: json['period'] as String? ?? '',
        status: RentStatus.fromWire(json['status'] as String?),
        amountDue: _toDouble(json['amount_due']),
        amountPaid: _toDouble(json['amount_paid']),
        dueDate: _toDate(json['due_date']),
        paidAt: _toDate(json['paid_at']),
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );
}

// ── TenantReceipt ──────────────────────────────────────────────────────────

/// One verified rent receipt for the authenticated tenant, returned in the
/// list from `GET /api/v1/me/receipts`.
///
/// [receiptRef] is the signed URL for the generated receipt PDF (may be empty
/// when the receipt hasn't been generated yet). [amount] comes back as a DRF
/// `DecimalField` string.
@freezed
abstract class TenantReceipt with _$TenantReceipt {
  const factory TenantReceipt({
    required String id,
    @Default('') String period,
    @Default(0) double amount,
    @Default('') String receiptRef,
    DateTime? verifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TenantReceipt;

  static TenantReceipt fromJson(Map<String, dynamic> json) => TenantReceipt(
        id: json['id']?.toString() ?? '',
        period: json['period'] as String? ?? '',
        amount: _toDouble(json['amount']),
        receiptRef: json['receipt_ref'] as String? ?? '',
        verifiedAt: _toDate(json['verified_at']),
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );
}

// ── TenantRecord ───────────────────────────────────────────────────────────

/// The authenticated tenant's private good-tenant record / self-rating,
/// managed via `GET/POST/PATCH /api/v1/me/record`.
///
/// STRICTLY PRIVATE — the [consent] field controls whether this record is
/// ever shared with future landlords. [rating] is 1–5 stars; [notes] is the
/// private memo. Both are editable client-side.
@freezed
abstract class TenantRecord with _$TenantRecord {
  const factory TenantRecord({
    required String id,
    @Default(0) int rating,
    @Default('') String notes,
    @Default(RecordConsent.private) RecordConsent consent,
    @Default(0) int onTimeMonths,
    @Default(0) int completedLeases,
    @Default(0.0) double averageRating,
    @Default(0) int disputes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TenantRecord;

  static TenantRecord fromJson(Map<String, dynamic> json) => TenantRecord(
        id: json['id']?.toString() ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        notes: json['notes'] as String? ?? '',
        consent: RecordConsent.fromWire(json['consent'] as String?),
        onTimeMonths: (json['on_time_months'] as num?)?.toInt() ?? 0,
        completedLeases: (json['completed_leases'] as num?)?.toInt() ?? 0,
        averageRating: _toDouble(json['average_rating']),
        disputes: (json['disputes'] as num?)?.toInt() ?? 0,
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );
}

// ── TenantMaintenanceReport ────────────────────────────────────────────────

/// A maintenance report submitted by the authenticated tenant via
/// `POST /api/v1/maintenance/reports`.
@freezed
abstract class TenantMaintenanceReport with _$TenantMaintenanceReport {
  const factory TenantMaintenanceReport({
    required String id,
    @Default('') String description,
    @Default(TenantMaintenanceCategory.other) TenantMaintenanceCategory category,
    @Default('') String photoRef,
    @Default(TenantMaintenanceStatus.open) TenantMaintenanceStatus status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TenantMaintenanceReport;

  static TenantMaintenanceReport fromJson(Map<String, dynamic> json) =>
      TenantMaintenanceReport(
        id: json['id']?.toString() ?? '',
        description: json['description'] as String? ?? '',
        category: TenantMaintenanceCategory.fromWire(
          json['category'] as String?,
        ),
        photoRef: json['photo_ref'] as String? ?? '',
        status: TenantMaintenanceStatus.fromWire(json['status'] as String?),
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );
}

// ── helpers ────────────────────────────────────────────────────────────────

double _toDouble(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

DateTime? _toDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
