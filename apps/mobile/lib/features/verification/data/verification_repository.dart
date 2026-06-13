import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/verification_result.dart';

/// Network access for the NID verification flow (EPIC-17).
///
/// Consumes the verify endpoint added by T-004 (`POST /tenants/:id/verify`) and
/// the tenant detail endpoint to read a previously stored [VerificationResult].
/// **No raw EC payload is ever returned** — the server filters it and only
/// surfaces `verification_status` + an opaque `provider_ref`.
class VerificationRepository {
  const VerificationRepository(this._dio);

  final Dio _dio;

  /// `POST /tenants/{tenantId}/verify` — trigger NID EC verification.
  ///
  /// [consent] must be `true` (landlord has attested the tenant gave consent).
  /// The server forwards the tenant's stored (encrypted) NID to the EC service,
  /// receives Matched/Not Matched, and returns only the opaque result + ref.
  /// Raw EC fields are **never** echoed back and must never be logged here.
  Future<VerificationResult> verify(String tenantId, {required bool consent}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.tenantVerify(tenantId),
        data: <String, dynamic>{'consent': consent},
      );
      return VerificationResult.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `GET /tenants/{tenantId}` — read the stored verification status for a
  /// tenant.
  ///
  /// Returns `null` when the tenant has no verification record yet (i.e.
  /// `verification_status == 'unverified'` or the tenant is not found).
  /// Only status + providerRef are extracted — no raw EC fields.
  Future<VerificationResult?> getVerification(String tenantId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.tenant(tenantId),
      );
      final data = res.data ?? const <String, dynamic>{};
      final status = data['verification_status'] as String?;
      if (status == null || status == 'unverified') return null;
      return VerificationResult(
        tenantId: tenantId,
        status: VerificationResultStatus.fromWire(status),
        providerRef: data['provider_ref'] as String? ?? '',
        verifiedAt: _toDate(data['verified_at']),
      );
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  static DateTime? _toDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  ApiException _asApiException(DioException e) {
    final err = e.error;
    return err is ApiException ? err : ApiException.fromDio(e);
  }
}
