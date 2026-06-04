import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/dmp_pdf_result.dart';
import 'models/dmp_preview.dart';

/// Network access for the DMP form (EPIC-05 T-007/T-008).
///
/// Reads the assembled, **masked-NID** preview data the landlord reviews, then
/// generates the PDF and downloads its bytes for preview/share. The full NID
/// never crosses the wire as text — masking happens server-side (T-004) and the
/// full value lives only inside the rendered PDF. Errors surface as
/// [ApiException].
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

  /// `POST /tenants/{id}/dmpform/pdf` — assemble → render → store → record the
  /// PDF and return a signed download URL ([DmpPdfResult]). Free-tier allowed
  /// (no entitlement gate; the wedge must work for everyone). Owner-scoped.
  Future<DmpPdfResult> generatePdf(String tenantId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.tenantDmpFormPdf(tenantId),
      );
      return DmpPdfResult.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      final err = e.error;
      throw err is ApiException ? err : ApiException.fromDio(e);
    }
  }

  /// Downloads the generated PDF bytes from a (short-lived) signed [url], for
  /// rendering in the preview and sharing/saving as a file. The signed URL is
  /// absolute and already authorized, so it is fetched as raw bytes without the
  /// app's auth headers carried onto a foreign host.
  Future<Uint8List> fetchPdfBytes(String url) async {
    try {
      final res = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(res.data ?? const <int>[]);
    } on DioException catch (e) {
      final err = e.error;
      throw err is ApiException ? err : ApiException.fromDio(e);
    }
  }
}
