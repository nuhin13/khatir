import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/maintenance_enums.dart';
import 'models/models.dart';

/// Optional list/export/summary filters shared by the expense reads. All fields
/// are optional and map to query params; they only ever **narrow** the
/// already-`for_user`-scoped set server-side. [dateFrom] / [dateTo] are
/// `YYYY-MM-DD` ISO days.
class ExpenseFilter {
  const ExpenseFilter({
    this.unitId,
    this.buildingId,
    this.dateFrom,
    this.dateTo,
  });

  /// `?unit=<id>` — restrict to one unit.
  final String? unitId;

  /// `?building=<id>` — restrict to one building (all its units).
  final String? buildingId;

  /// `?date_from=<YYYY-MM-DD>` — inclusive lower bound on the expense date.
  final DateTime? dateFrom;

  /// `?date_to=<YYYY-MM-DD>` — inclusive upper bound on the expense date.
  final DateTime? dateTo;

  /// Builds the query-param map, omitting any unset filter.
  Map<String, dynamic> toQueryParameters() => <String, dynamic>{
        if (unitId != null) 'unit': unitId,
        if (buildingId != null) 'building': buildingId,
        if (dateFrom != null) 'date_from': _isoDate(dateFrom!),
        if (dateTo != null) 'date_to': _isoDate(dateTo!),
      };

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Network access for expenses (EPIC-08 T-003 endpoints): list (filtered),
/// fetch/create/update/delete one expense, the per-category/per-month [summary]
/// aggregation, and a CSV [exportCsv] download.
///
/// Expenses are scoped server-side (`for_user` via unit → landlord), so a
/// foreign/unknown id resolves to **404** (never 403). `source` is server-driven
/// (`manual` for direct entries; `request` auto-expenses come from the resolve
/// action and are not editable here). `amount` is sent as a number and comes back
/// as a DRF `DecimalField` string (parsed in [Expense]). Errors surface as
/// [ApiException]. Detail/create/update return the resource directly (no
/// envelope); the list comes back as `{results, pagination}`.
class ExpenseRepository {
  const ExpenseRepository(this._dio);

  final Dio _dio;

  /// `GET /expenses` — the caller's expenses (one page), optionally narrowed by
  /// [filter]. Scoped server-side via `for_user`, returned in the standard
  /// `{results, pagination}` envelope, so only the `results` array is unwrapped.
  /// Both manual and auto (`source=request`) expenses appear.
  Future<List<Expense>> listExpenses({ExpenseFilter? filter}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.expenses,
        queryParameters: filter?.toQueryParameters(),
      );
      final data = res.data ?? const <String, dynamic>{};
      final results = data['results'];
      if (results is! List) return const <Expense>[];
      return results
          .whereType<Map<String, dynamic>>()
          .map(Expense.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `GET /expenses/{id}` — one expense the caller owns. Foreign/unknown ids
  /// resolve to **404** (surfaced as an [ApiException]).
  Future<Expense> getExpense(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.expense(id),
      );
      return Expense.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /expenses` — log a manual expense on a unit (T-003 §7). The unit is
  /// resolved+scoped server-side from [unitId]; `source` is forced to `manual`.
  /// [category] / [note] / [receiptRef] are sent only when supplied (the server
  /// defaults category to `other`). [date] is the `YYYY-MM-DD` day incurred.
  /// Returns the persisted expense.
  Future<Expense> createExpense({
    required String unitId,
    required double amount,
    required DateTime date,
    ExpenseCategory? category,
    String? note,
    String? receiptRef,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.expenses,
        data: <String, dynamic>{
          'unit_id': unitId,
          'amount': amount,
          'date': ExpenseFilter._isoDate(date),
          if (category != null) 'category': category.wire,
          if (note != null) 'note': note,
          if (receiptRef != null) 'receipt_ref': receiptRef,
        },
      );
      return Expense.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `PATCH /expenses/{id}` — partial-update a **manual** expense (T-003 §7).
  /// Only the supplied fields are sent; the unit/source/request are immutable. An
  /// auto-expense (`source=request`) is not editable (server-enforced). Returns
  /// the updated expense.
  Future<Expense> updateExpense(
    String id, {
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? note,
    String? receiptRef,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.expense(id),
        data: <String, dynamic>{
          if (amount != null) 'amount': amount,
          if (date != null) 'date': ExpenseFilter._isoDate(date),
          if (category != null) 'category': category.wire,
          if (note != null) 'note': note,
          if (receiptRef != null) 'receipt_ref': receiptRef,
        },
      );
      return Expense.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `DELETE /expenses/{id}` — soft-delete a manual expense (T-003 §7). Returns
  /// 204 No Content; foreign/unknown ids resolve to **404**.
  Future<void> deleteExpense(String id) async {
    try {
      await _dio.delete<void>(ApiEndpoints.expense(id));
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `GET /expenses/summary` — per-category and per-month totals for the
  /// dashboard (T-012 §7), optionally narrowed by [filter]. Amounts arrive as
  /// `Decimal` strings (parsed in [ExpenseSummary]); each month bucket is the
  /// first day of that month.
  Future<ExpenseSummary> summary({ExpenseFilter? filter}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.expensesSummary,
        queryParameters: filter?.toQueryParameters(),
      );
      return ExpenseSummary.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `GET /expenses/export` — the (scoped + filtered) expenses as CSV text
  /// (T-003 §7). The backend streams the rows; here they are received as a single
  /// string for the caller to save/share. Uses the same [filter] as [listExpenses]
  /// so the export can never leak another user's expenses.
  Future<String> exportCsv({ExpenseFilter? filter}) async {
    try {
      final res = await _dio.get<String>(
        ApiEndpoints.expensesExport,
        queryParameters: filter?.toQueryParameters(),
        options: Options(responseType: ResponseType.plain),
      );
      return res.data ?? '';
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  ApiException _asApiException(DioException e) {
    final err = e.error;
    return err is ApiException ? err : ApiException.fromDio(e);
  }
}
