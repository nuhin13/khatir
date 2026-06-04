import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/lease_enums.dart';
import 'models/models.dart';

/// Network access for leases + rent schedule (EPIC-06 T-003/T-004 endpoints):
/// create (draft) / partial-update / activate / terminate, plus reads for the
/// rent schedule and a unit's current (active) lease.
///
/// Leases are scoped server-side (`for_user`), so a foreign/unknown lease id
/// resolves to **404** (never 403). The `landlord` is derived server-side from
/// the unit owner and is never sent by the client. Monetary fields are sent as
/// numbers and come back as DRF `DecimalField` strings (parsed in [Lease]).
/// Errors surface as [ApiException].
class LeaseRepository {
  const LeaseRepository(this._dio);

  final Dio _dio;

  /// `GET /leases/{id}` — one lease the caller owns.
  Future<Lease> getLease(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.lease(id));
      return Lease.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /leases` — create a **draft** lease (T-003 §7). The landlord is
  /// server-derived from the unit owner; status is not client-settable.
  /// [advance] is sent only when supplied. Returns the persisted draft.
  Future<Lease> createLease({
    required String unitId,
    required String tenantId,
    required DateTime startDate,
    required DateTime endDate,
    required double rent,
    double? advance,
  }) async {
    final body = <String, dynamic>{
      'unit_id': unitId,
      'tenant_id': tenantId,
      'start_date': _date(startDate),
      'end_date': _date(endDate),
      'rent': rent,
      if (advance != null) 'advance': advance,
    };
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.leases,
        data: body,
      );
      return Lease.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `PATCH /leases/{id}` — partial update of a **draft** lease's terms/dates
  /// (T-003 §7). Only non-null fields are sent. FKs and status are immutable.
  Future<Lease> updateLease(
    String id, {
    DateTime? startDate,
    DateTime? endDate,
    double? rent,
    double? advance,
    String? signedPdfRef,
  }) async {
    final body = <String, dynamic>{
      if (startDate != null) 'start_date': _date(startDate),
      if (endDate != null) 'end_date': _date(endDate),
      if (rent != null) 'rent': rent,
      if (advance != null) 'advance': advance,
      if (signedPdfRef != null) 'signed_pdf_ref': signedPdfRef,
    };
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.lease(id),
        data: body,
      );
      return Lease.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /leases/{id}/activate` — activate a draft lease; the server
  /// generates its rent schedule (T-003 §7). Returns the activated lease.
  Future<Lease> activateLease(String id) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.leaseActivate(id),
      );
      return Lease.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /leases/{id}/terminate` — close an active lease (T-003 §7).
  /// [status] chooses [LeaseStatus.ended] (natural end-of-term) vs.
  /// [LeaseStatus.terminated] (early close); the server defaults to terminated
  /// when omitted, so only `ended`/`terminated` are accepted here.
  Future<Lease> terminateLease(String id, {LeaseStatus? status}) async {
    final body = <String, dynamic>{
      if (status != null) 'status': status.wire,
    };
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.leaseTerminate(id),
        data: body,
      );
      return Lease.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `GET /leases/{id}/schedule` — the lease's rent schedule, chronologically
  /// (T-004 §7). Returns a bare JSON array of read-only rows.
  Future<List<RentSchedule>> getSchedule(String id) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        ApiEndpoints.leaseSchedule(id),
      );
      final data = res.data ?? const <dynamic>[];
      return data
          .whereType<Map<String, dynamic>>()
          .map(RentSchedule.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `GET /units/{id}/lease` — a unit's current (active) lease plus the
  /// embedded tenant summary (T-004 §7). The unit is scoped `for_user`; when it
  /// has no active lease the server returns **404** (there is no "empty" current
  /// lease), surfaced here as an [ApiException] with status 404.
  Future<UnitLease> getUnitLease(String unitId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.unitLease(unitId),
      );
      return UnitLease.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `YYYY-MM-DD` — the wire shape DRF `DateField` expects.
  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  ApiException _asApiException(DioException e) {
    final err = e.error;
    return err is ApiException ? err : ApiException.fromDio(e);
  }
}
