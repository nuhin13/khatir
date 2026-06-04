import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/dmp_preview.dart';

/// Network access for the DMP-form preview (EPIC-05 T-007).
///
/// Reads the assembled, **masked-NID** form data the landlord reviews before
/// generating the PDF. The full NID never crosses the wire — masking happens
/// server-side (T-004). Errors surface as [ApiException].
class DmpFormRepository {
  const DmpFormRepository(this._dio);

  final Dio _dio;

  /// `GET /tenants/{id}/dmpform` — the assembled DMP preview for a tenant.
  ///
  /// The tenant is owner-scoped server-side, so a foreign/unknown id 404s into
  /// an [ApiException] (surfaced as the error state) rather than leaking.
  Future<DmpPreview> getPreview(String tenantId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.tenantDmpForm(tenantId),
      );
      return DmpPreview.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      final err = e.error;
      throw err is ApiException ? err : ApiException.fromDio(e);
    }
  }
}
