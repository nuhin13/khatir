import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/maintenance_enums.dart';
import 'models/models.dart';

/// Network access for maintenance requests (EPIC-08 T-002 endpoints): list the
/// queue, fetch/create/update one request, and resolve it (recording the cost,
/// which auto-creates exactly one expense server-side).
///
/// Requests are scoped server-side (`for_user` via unit → landlord), so a
/// foreign/unknown id resolves to **404** (never 403). The owning landlord is
/// derived server-side and is never sent by the client; the `status` and
/// resolution fields are server-driven through [resolve]. `resolution_cost`
/// comes back as a DRF `DecimalField` string (parsed in [MaintenanceRequest]).
/// Errors surface as [ApiException]. Detail/create/resolve return the resource
/// directly (no envelope); the list comes back as `{results, pagination}`.
class MaintenanceRepository {
  const MaintenanceRepository(this._dio);

  final Dio _dio;

  /// `GET /maintenance` — the caller's maintenance queue (one page). Scoped
  /// server-side via `for_user`, returned in the standard `{results, pagination}`
  /// envelope, so only the `results` array is unwrapped (the queue screen renders
  /// a single page; pagination cursors are ignored for now). Optional [status]
  /// and [unitId] filters map to `?status=<wire>` / `?unit=<id>` so a tab can
  /// show only e.g. open requests, or those on one unit.
  Future<List<MaintenanceRequest>> listQueue({
    MaintenanceStatus? status,
    String? unitId,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.maintenance,
        queryParameters: <String, dynamic>{
          if (status != null) 'status': status.wire,
          if (unitId != null) 'unit': unitId,
        },
      );
      final data = res.data ?? const <String, dynamic>{};
      final results = data['results'];
      if (results is! List) return const <MaintenanceRequest>[];
      return results
          .whereType<Map<String, dynamic>>()
          .map(MaintenanceRequest.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `GET /maintenance/{id}` — one request the caller owns. Foreign/unknown ids
  /// resolve to **404** (surfaced as an [ApiException]).
  Future<MaintenanceRequest> getRequest(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.maintenanceRequest(id),
      );
      return MaintenanceRequest.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /maintenance` — create a request on a unit (T-002 §7). The unit is
  /// resolved+scoped server-side from [unitId]; the request is always created
  /// `open`. [category] / [photoRef] / [leaseId] are sent only when supplied
  /// (the server defaults category to `other`). Returns the persisted request.
  Future<MaintenanceRequest> createRequest({
    required String unitId,
    required String description,
    MaintenanceCategory? category,
    String? photoRef,
    String? leaseId,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.maintenance,
        data: <String, dynamic>{
          'unit_id': unitId,
          'description': description,
          if (category != null) 'category': category.wire,
          if (photoRef != null) 'photo_ref': photoRef,
          if (leaseId != null) 'lease_id': leaseId,
        },
      );
      return MaintenanceRequest.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `PATCH /maintenance/{id}` — partial-update an **open** request's descriptive
  /// fields (T-002 §7). Only the supplied fields are sent; the unit and status
  /// are immutable here. Returns the updated request.
  Future<MaintenanceRequest> updateRequest(
    String id, {
    String? description,
    MaintenanceCategory? category,
    String? photoRef,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.maintenanceRequest(id),
        data: <String, dynamic>{
          if (description != null) 'description': description,
          if (category != null) 'category': category.wire,
          if (photoRef != null) 'photo_ref': photoRef,
        },
      );
      return MaintenanceRequest.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /maintenance/{id}/resolve` — resolve a request with the [cost] that
  /// becomes the auto-expense (T-002 §7), plus an optional [note]. Idempotent
  /// server-side (exactly one expense per resolve). Returns the resolved request
  /// (now `resolved`, carrying the resolution fields).
  Future<MaintenanceRequest> resolve(
    String id, {
    required double cost,
    String? note,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.maintenanceResolve(id),
        data: <String, dynamic>{
          'cost': cost,
          if (note != null) 'note': note,
        },
      );
      return MaintenanceRequest.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  ApiException _asApiException(DioException e) {
    final err = e.error;
    return err is ApiException ? err : ApiException.fromDio(e);
  }
}
