import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'dashboard_model.dart';

/// Network access for the dashboard (EPIC-09 T-002 endpoint): a single
/// `GET /dashboard` returns every landlord metric in one call, so the dashboard
/// screen never fans out one request per card/chart.
///
/// The payload is **owner-scoped** server-side (`for_user`) and cached per user
/// for a short TTL, so the client just reads it. The optional [months] window
/// maps to `?months=N`; when omitted the server applies the configured default
/// (`dashboard_months_default`). All money fields come back as DRF
/// `DecimalField` strings (parsed in [DashboardData]). Errors surface as
/// [ApiException].
class DashboardRepository {
  const DashboardRepository(this._dio);

  final Dio _dio;

  /// `GET /dashboard` — the caller's full dashboard payload. The response body
  /// is the metrics object directly (no `{results}` envelope). An optional
  /// [months] overrides the server's default month window; when null the param
  /// is omitted so the server applies its configured default.
  Future<DashboardData> fetchDashboard({int? months}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.dashboard,
        queryParameters: <String, dynamic>{'months': ?months},
      );
      return DashboardData.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  ApiException _asApiException(DioException e) {
    final err = e.error;
    return err is ApiException ? err : ApiException.fromDio(e);
  }
}
