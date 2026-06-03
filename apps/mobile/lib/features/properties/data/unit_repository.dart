import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/property_enums.dart';
import 'models/unit.dart';

/// Network access for units (T-004 endpoints): list/create under a building,
/// bulk-generate, and single-unit detail/update/delete.
///
/// Units are scoped via their building (or `for_user` on the single-unit
/// routes), so foreign/unknown ids resolve to 404. List responses come wrapped
/// in the `{results, pagination}` envelope; create/generate/detail return the
/// resource(s) directly. Errors surface as [ApiException].
class UnitRepository {
  const UnitRepository(this._dio);

  final Dio _dio;

  /// `GET /buildings/{id}/units` — units in a building (one page).
  Future<List<Unit>> listUnits(String buildingId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.buildingUnits(buildingId),
      );
      final data = res.data ?? const <String, dynamic>{};
      final results = data['results'];
      if (results is! List) return const <Unit>[];
      return results
          .whereType<Map<String, dynamic>>()
          .map(Unit.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `GET /units/{id}` — one unit the caller owns.
  Future<Unit> getUnit(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.unit(id));
      return Unit.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /buildings/{id}/units` — create a single unit. Building comes from
  /// the URL; only non-null fields are sent.
  Future<Unit> createUnit(
    String buildingId, {
    required String label,
    UnitType? type,
    double? rent,
    List<String>? amenities,
    UnitStatus? status,
    DateTime? availableFrom,
  }) async {
    final body = <String, dynamic>{
      'label': label,
      if (type != null) 'type': type.wire,
      if (rent != null) 'rent': rent,
      if (amenities != null) 'amenities': amenities,
      if (status != null) 'status': status.wire,
      if (availableFrom != null) 'available_from': _date(availableFrom),
    };
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.buildingUnits(buildingId),
        data: body,
      );
      return Unit.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /buildings/{id}/units/generate` — bulk-create units from
  /// `floors × perFloor` under [scheme], plus [custom] labels, minus [removed].
  /// Returns the newly inserted units.
  Future<List<Unit>> generateUnits(
    String buildingId, {
    required int floors,
    required int perFloor,
    required UnitScheme scheme,
    List<String>? custom,
    List<String>? removed,
  }) async {
    final body = <String, dynamic>{
      'floors': floors,
      'per_floor': perFloor,
      'scheme': scheme.wire,
      if (custom != null) 'custom': custom,
      if (removed != null) 'removed': removed,
    };
    try {
      final res = await _dio.post<List<dynamic>>(
        ApiEndpoints.buildingUnitsGenerate(buildingId),
        data: body,
      );
      final data = res.data ?? const <dynamic>[];
      return data
          .whereType<Map<String, dynamic>>()
          .map(Unit.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `PATCH /units/{id}` — partial update; only non-null fields are sent.
  Future<Unit> updateUnit(
    String id, {
    String? label,
    UnitType? type,
    double? rent,
    List<String>? amenities,
    UnitStatus? status,
    DateTime? availableFrom,
  }) async {
    final body = <String, dynamic>{
      if (label != null) 'label': label,
      if (type != null) 'type': type.wire,
      if (rent != null) 'rent': rent,
      if (amenities != null) 'amenities': amenities,
      if (status != null) 'status': status.wire,
      if (availableFrom != null) 'available_from': _date(availableFrom),
    };
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.unit(id),
        data: body,
      );
      return Unit.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `DELETE /units/{id}` — soft-delete a unit (204).
  Future<void> deleteUnit(String id) async {
    try {
      await _dio.delete<void>(ApiEndpoints.unit(id));
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
