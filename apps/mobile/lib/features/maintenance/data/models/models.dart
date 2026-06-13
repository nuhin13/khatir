import 'package:freezed_annotation/freezed_annotation.dart';

import 'maintenance_enums.dart';

part 'models.freezed.dart';

/// A persisted maintenance request, mirroring the backend
/// `MaintenanceRequestSerializer` (`{id, unit_id, lease_id, category,
/// description, photo_ref, status, resolved_at, resolution_cost,
/// resolution_note, created_at, updated_at}`).
///
/// The FK ids ([unitId], [leaseId]) and [status] are read-only server-side; the
/// client never sets them — `status` and the resolution fields are server-driven
/// through the resolve action (T-002). [resolutionCost] arrives as a DRF
/// `DecimalField` **string** (nullable until resolved) and is parsed to a
/// nullable [double]. Unknown keys are ignored; nullable timestamps tolerate
/// absent values.
@freezed
abstract class MaintenanceRequest with _$MaintenanceRequest {
  const factory MaintenanceRequest({
    required String id,
    @Default('') String unitId,
    @Default('') String leaseId,
    @Default(MaintenanceCategory.other) MaintenanceCategory category,
    @Default('') String description,
    @Default('') String photoRef,
    @Default(MaintenanceStatus.open) MaintenanceStatus status,
    DateTime? resolvedAt,
    double? resolutionCost,
    @Default('') String resolutionNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _MaintenanceRequest;

  /// Parses a maintenance-request payload. `category` degrades to `other` and
  /// `status` to `open`; `resolution_cost` tolerates null (unresolved);
  /// timestamps tolerate null; ids serialize to strings.
  static MaintenanceRequest fromJson(Map<String, dynamic> json) =>
      MaintenanceRequest(
        id: json['id']?.toString() ?? '',
        unitId: json['unit_id']?.toString() ?? '',
        leaseId: json['lease_id']?.toString() ?? '',
        category: MaintenanceCategory.fromWire(json['category'] as String?),
        description: json['description'] as String? ?? '',
        photoRef: json['photo_ref'] as String? ?? '',
        status: MaintenanceStatus.fromWire(json['status'] as String?),
        resolvedAt: _toDate(json['resolved_at']),
        resolutionCost: _toNullableDouble(json['resolution_cost']),
        resolutionNote: json['resolution_note'] as String? ?? '',
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );
}

/// A persisted expense on a unit, mirroring the backend `ExpenseSerializer`
/// (`{id, unit_id, request_id, category, amount, date, source, note,
/// receipt_ref, created_at, updated_at}`).
///
/// The FK ids ([unitId], [requestId]) and [source] are read-only server-side:
/// auto-expenses ([ExpenseSource.request]) come from the resolve action, while
/// manually-logged ones ([ExpenseSource.manual]) are created/edited through the
/// expense endpoint. [amount] arrives as a DRF `DecimalField` **string** and is
/// parsed to [double]. [date] is the `YYYY-MM-DD` day the expense was incurred.
/// Unknown keys are ignored; nullable timestamps tolerate absent values.
@freezed
abstract class Expense with _$Expense {
  const factory Expense({
    required String id,
    @Default('') String unitId,
    @Default('') String requestId,
    @Default(ExpenseCategory.other) ExpenseCategory category,
    @Default(0) double amount,
    DateTime? date,
    @Default(ExpenseSource.manual) ExpenseSource source,
    @Default('') String note,
    @Default('') String receiptRef,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Expense;

  /// Parses an expense payload. `category` degrades to `other` and `source` to
  /// `manual`; `amount` tolerates null; `date` and timestamps tolerate null; ids
  /// serialize to strings.
  static Expense fromJson(Map<String, dynamic> json) => Expense(
        id: json['id']?.toString() ?? '',
        unitId: json['unit_id']?.toString() ?? '',
        requestId: json['request_id']?.toString() ?? '',
        category: ExpenseCategory.fromWire(json['category'] as String?),
        amount: _toDouble(json['amount']),
        date: _toDate(json['date']),
        source: ExpenseSource.fromWire(json['source'] as String?),
        note: json['note'] as String? ?? '',
        receiptRef: json['receipt_ref'] as String? ?? '',
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );
}

/// One row of the expense summary's per-category totals, mirroring a `by_category`
/// entry from `GET /expenses/summary` (`{category, total}`). [total] arrives as a
/// `Decimal` **string** and is parsed to [double] to preserve the displayed value.
@freezed
abstract class ExpenseCategoryTotal with _$ExpenseCategoryTotal {
  const factory ExpenseCategoryTotal({
    @Default(ExpenseCategory.other) ExpenseCategory category,
    @Default(0) double total,
  }) = _ExpenseCategoryTotal;

  /// Parses a `by_category` row. `category` degrades to `other`; `total`
  /// tolerates null.
  static ExpenseCategoryTotal fromJson(Map<String, dynamic> json) =>
      ExpenseCategoryTotal(
        category: ExpenseCategory.fromWire(json['category'] as String?),
        total: _toDouble(json['total']),
      );
}

/// One row of the expense summary's per-month totals, mirroring a `by_month`
/// entry from `GET /expenses/summary` (`{month, total}`). [month] is the first
/// day of the bucket month (ISO date); [total] arrives as a `Decimal` **string**.
@freezed
abstract class ExpenseMonthTotal with _$ExpenseMonthTotal {
  const factory ExpenseMonthTotal({
    DateTime? month,
    @Default(0) double total,
  }) = _ExpenseMonthTotal;

  /// Parses a `by_month` row. `month` and `total` tolerate null.
  static ExpenseMonthTotal fromJson(Map<String, dynamic> json) =>
      ExpenseMonthTotal(
        month: _toDate(json['month']),
        total: _toDouble(json['total']),
      );
}

/// The expense summary for the dashboard, mirroring `GET /expenses/summary`
/// (`{by_category: [...], by_month: [...]}`). Both lists default to empty so a
/// partial/empty response renders cleanly.
@freezed
abstract class ExpenseSummary with _$ExpenseSummary {
  const factory ExpenseSummary({
    @Default(<ExpenseCategoryTotal>[]) List<ExpenseCategoryTotal> byCategory,
    @Default(<ExpenseMonthTotal>[]) List<ExpenseMonthTotal> byMonth,
  }) = _ExpenseSummary;

  /// Parses a summary payload. Missing/non-list buckets degrade to empty lists.
  static ExpenseSummary fromJson(Map<String, dynamic> json) => ExpenseSummary(
        byCategory: _parseList(json['by_category'], ExpenseCategoryTotal.fromJson),
        byMonth: _parseList(json['by_month'], ExpenseMonthTotal.fromJson),
      );
}

List<T> _parseList<T>(
  Object? value,
  T Function(Map<String, dynamic>) parse,
) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(parse)
      .toList(growable: false);
}

double _toDouble(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

double? _toNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _toDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
