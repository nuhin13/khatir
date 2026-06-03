import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/portfolio_summary.dart';

/// Network access for the portfolio summary (T-005 endpoint).
///
/// `GET /portfolio` returns the caller's buildings (each with unit counts,
/// occupancy breakdown, and rent sum) plus a top-level totals object. The
/// payload is self-scoped server-side via `for_user`. Errors surface as
/// [ApiException].
class PortfolioRepository {
  const PortfolioRepository(this._dio);

  final Dio _dio;

  /// `GET /portfolio` — the caller's portfolio summary.
  Future<PortfolioSummary> getPortfolio() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.portfolio);
      return PortfolioSummary.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      final err = e.error;
      throw err is ApiException ? err : ApiException.fromDio(e);
    }
  }
}
