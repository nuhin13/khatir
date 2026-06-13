import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/building.dart';
import 'models/property_enums.dart';

/// Network access for buildings (T-003 endpoints).
///
/// All reads are self-scoped server-side via `for_user`, so a foreign/unknown
/// id resolves to 404. List responses come wrapped in the
/// `{results, pagination}` envelope; detail/create return the resource
/// directly. Errors are surfaced as [ApiException] (normalised by the dio error
/// interceptor) so callers branch on [ApiException.statusCode].
class BuildingRepository {
  const BuildingRepository(this._dio);

  final Dio _dio;

  /// `GET /buildings` — the caller's buildings (one page).
  Future<List<Building>> listBuildings() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.buildings);
      final data = res.data ?? const <String, dynamic>{};
      final results = data['results'];
      if (results is! List) return const <Building>[];
      return results
          .whereType<Map<String, dynamic>>()
          .map(Building.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `GET /buildings/{id}` — one building the caller owns.
  Future<Building> getBuilding(String id) async {
    try {
      final res =
          await _dio.get<Map<String, dynamic>>(ApiEndpoints.building(id));
      return Building.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /buildings` — create a building. Owner is set server-side; only the
  /// non-null fields are sent.
  Future<Building> createBuilding({
    required String name,
    required Area area,
    required String address,
    double? lat,
    double? lng,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'area': area.wire,
      'address': address,
      if (lat != null) 'lat': double.parse(lat.toStringAsFixed(6)),
      if (lng != null) 'lng': double.parse(lng.toStringAsFixed(6)),
    };
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.buildings,
        data: body,
      );
      return Building.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `PATCH /buildings/{id}` — partial update; only non-null fields are sent.
  Future<Building> updateBuilding(
    String id, {
    String? name,
    Area? area,
    String? address,
    double? lat,
    double? lng,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (area != null) 'area': area.wire,
      if (address != null) 'address': address,
      if (lat != null) 'lat': double.parse(lat.toStringAsFixed(6)),
      if (lng != null) 'lng': double.parse(lng.toStringAsFixed(6)),
    };
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.building(id),
        data: body,
      );
      return Building.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `DELETE /buildings/{id}` — soft-delete a building (204).
  Future<void> deleteBuilding(String id) async {
    try {
      await _dio.delete<void>(ApiEndpoints.building(id));
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  ApiException _asApiException(DioException e) {
    final err = e.error;
    return err is ApiException ? err : ApiException.fromDio(e);
  }
}
