import 'package:freezed_annotation/freezed_annotation.dart';

import '../../maintenance/data/models/maintenance_enums.dart';

part 'dashboard_model.freezed.dart';

/// One `YYYY-MM` point of the collected-vs-expense time series, mirroring a
/// `monthly_series` entry from `GET /dashboard` (`{period, collected, expense}`).
///
/// [period] is the canonical `YYYY-MM` bucket label (kept as the raw string so
/// the chart can render it without re-deriving a month). [collected] and
/// [expense] arrive as DRF `DecimalField` **strings** and are parsed to
/// [double]; the series spans the requested window oldest → newest, with empty
/// months zero-filled server-side.
@freezed
abstract class MonthPoint with _$MonthPoint {
  const factory MonthPoint({
    @Default('') String period,
    @Default(0) double collected,
    @Default(0) double expense,
  }) = _MonthPoint;

  /// Parses a `monthly_series` row. `period` defaults to empty; the money
  /// fields tolerate null.
  static MonthPoint fromJson(Map<String, dynamic> json) => MonthPoint(
        period: json['period']?.toString() ?? '',
        collected: _toDouble(json['collected']),
        expense: _toDouble(json['expense']),
      );
}

/// One expense-category total in the top-categories breakdown, mirroring a
/// `top_expense_categories` entry from `GET /dashboard` (`{category, amount}`).
///
/// [category] reuses the shared [ExpenseCategory] enum (same wire values as the
/// expense domain); unknown/absent values degrade to [ExpenseCategory.other].
/// [amount] arrives as a `Decimal` **string** and is parsed to [double].
@freezed
abstract class CategoryTotal with _$CategoryTotal {
  const factory CategoryTotal({
    @Default(ExpenseCategory.other) ExpenseCategory category,
    @Default(0) double amount,
  }) = _CategoryTotal;

  /// Parses a `top_expense_categories` row. `category` degrades to `other`;
  /// `amount` tolerates null.
  static CategoryTotal fromJson(Map<String, dynamic> json) => CategoryTotal(
        category: ExpenseCategory.fromWire(json['category'] as String?),
        amount: _toDouble(json['amount']),
      );
}

/// The full dashboard payload, mirroring the backend `DashboardSerializer`
/// (EPIC-09 T-002 §7) — every landlord metric in a single response body:
/// `{total_collected, total_pending, total_overdue, collection_rate,
/// occupied_units, total_units, occupancy_rate, total_income, total_expense,
/// net, late_payer_count, monthly_series, top_expense_categories}`.
///
/// Money fields ([totalCollected], [totalPending], [totalOverdue],
/// [totalIncome], [totalExpense], [net]) arrive as DRF `DecimalField`
/// **strings** and are parsed to [double]; the rates are floats (0..1) and the
/// counts are ints. The two list fields default to empty so a partial/empty
/// response renders cleanly. Unknown keys are ignored.
@freezed
abstract class DashboardData with _$DashboardData {
  const factory DashboardData({
    @Default(0) double totalCollected,
    @Default(0) double totalPending,
    @Default(0) double totalOverdue,
    @Default(0) double collectionRate,
    @Default(0) int occupiedUnits,
    @Default(0) int totalUnits,
    @Default(0) double occupancyRate,
    @Default(0) double totalIncome,
    @Default(0) double totalExpense,
    @Default(0) double net,
    @Default(0) int latePayerCount,
    @Default(<MonthPoint>[]) List<MonthPoint> monthlySeries,
    @Default(<CategoryTotal>[]) List<CategoryTotal> topExpenseCategories,
  }) = _DashboardData;

  /// Parses a dashboard payload. All money fields tolerate null (→ 0); the rate
  /// and count fields tolerate null/string; the two list fields degrade to
  /// empty when absent or non-list.
  static DashboardData fromJson(Map<String, dynamic> json) => DashboardData(
        totalCollected: _toDouble(json['total_collected']),
        totalPending: _toDouble(json['total_pending']),
        totalOverdue: _toDouble(json['total_overdue']),
        collectionRate: _toDouble(json['collection_rate']),
        occupiedUnits: _toInt(json['occupied_units']),
        totalUnits: _toInt(json['total_units']),
        occupancyRate: _toDouble(json['occupancy_rate']),
        totalIncome: _toDouble(json['total_income']),
        totalExpense: _toDouble(json['total_expense']),
        net: _toDouble(json['net']),
        latePayerCount: _toInt(json['late_payer_count']),
        monthlySeries: _parseList(json['monthly_series'], MonthPoint.fromJson),
        topExpenseCategories:
            _parseList(json['top_expense_categories'], CategoryTotal.fromJson),
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

int _toInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
