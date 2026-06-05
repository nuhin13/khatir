import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/plan_models.dart';

/// Network access for the plan & billing screen (EPIC-10 T-007).
///
/// The plan catalogue and the caller's current subscription/usage both come
/// from one authenticated `GET /config/public` read (T-005) — the screen never
/// fetches tier prices separately. Subscribing/upgrading is a `POST
/// /billing/subscribe` with the chosen `tier_key` (T-004); payment is stubbed
/// server-side (a pending intent an admin confirms). Errors surface as
/// [ApiException].
class BillingRepository {
  const BillingRepository(this._dio);

  final Dio _dio;

  /// Reads `/config/public` and projects out the plan slice (tiers +
  /// subscription). An empty/absent body yields an empty [PlanConfig] rather
  /// than throwing so the screen can show its own empty state.
  Future<PlanConfig> fetchPlanConfig() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.publicConfig,
      );
      return PlanConfig.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /billing/subscribe` — subscribe / upgrade to [tierKey]. Payment is
  /// stubbed server-side; the call records the intent and returns the resulting
  /// subscription, which the screen ignores (it re-reads `/config/public` to
  /// refresh usage + the current-plan highlight).
  Future<void> subscribe(String tierKey) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.billingSubscribe,
        data: <String, dynamic>{'tier_key': tierKey},
      );
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  ApiException _asApiException(DioException e) {
    final err = e.error;
    return err is ApiException ? err : ApiException.fromDio(e);
  }
}
