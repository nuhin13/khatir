import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/warning_enums.dart';
import 'models/models.dart';

/// Network access for warnings (EPIC-20 T-002 endpoints):
/// issue / list + generate notice PDF.
///
/// Warnings are strictly private: scoped server-side to `for_user` so a
/// foreign/unknown lease id always resolves to **404** (never 403). All
/// endpoints are kill-switch gated by `warnings_feature` on the server; when
/// the flag is off the server returns a `feature_disabled` 403, surfaced here
/// as an [ApiException] with status 403.
class WarningRepository {
  const WarningRepository(this._dio);

  final Dio _dio;

  /// `POST /leases/{leaseId}/warnings` — issue a private warning. The
  /// landlord is derived server-side from the lease owner; the tenant is
  /// derived from the lease's active tenant. Returns the persisted warning.
  Future<Warning> issueWarning({
    required String leaseId,
    required WarningType warningType,
    required String reason,
  }) async {
    final body = <String, dynamic>{
      'warning_type': warningType.wire,
      'reason': reason,
    };
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.leaseWarnings(leaseId),
        data: body,
      );
      return Warning.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `GET /leases/{leaseId}/warnings` — list the caller's warnings for this
  /// lease (scoped server-side: only the landlord's own). Returns a bare
  /// array (no pagination envelope — warnings per lease are few).
  Future<List<Warning>> listWarnings(String leaseId) async {
    try {
      final res = await _dio.get<dynamic>(
        ApiEndpoints.leaseWarnings(leaseId),
      );
      final data = res.data;
      // The endpoint may return a list directly or a results envelope.
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        final results = data['results'];
        list = results is List ? results : const <dynamic>[];
      } else {
        list = const <dynamic>[];
      }
      return list
          .whereType<Map<String, dynamic>>()
          .map(Warning.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /warnings/{warningId}/notice` — generate the warning notice PDF.
  /// Returns the [WarningNotice] with a short-lived [signedUrl] for download.
  Future<WarningNotice> generateNotice(String warningId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.warningNotice(warningId),
      );
      return WarningNotice.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// Downloads the PDF bytes from the [signedUrl] returned by [generateNotice].
  /// Used by the notice-share screen to render and share the PDF.
  Future<Uint8List> fetchNoticePdfBytes(String signedUrl) async {
    try {
      final res = await _dio.get<List<int>>(
        signedUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(res.data ?? const <int>[]);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  ApiException _asApiException(DioException e) {
    final err = e.error;
    return err is ApiException ? err : ApiException.fromDio(e);
  }
}
