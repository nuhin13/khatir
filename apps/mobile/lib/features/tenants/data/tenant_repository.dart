import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/extracted_tenant.dart';

/// Network access for the add-tenant flows (EPIC-04). For now this owns the OCR
/// extraction call consumed by the NID capture (T-010) and review (T-011)
/// screens; later EPIC-04 tasks extend it (voice, create, list) per T-014.
///
/// Errors surface as [ApiException]. The NID image is uploaded as multipart and
/// is **not** persisted on the device beyond the upload (privacy, T-010 §15).
class TenantRepository {
  const TenantRepository(this._dio);

  final Dio _dio;

  /// `POST /tenants/ocr` — upload an NID image (multipart) for OCR extraction.
  ///
  /// Sends the raw [bytes] under the `image` field (matching the backend
  /// `OcrRequestSerializer.image` FileField) and returns the editable
  /// [ExtractedTenant] (fields + `photo_ref`). [filename] is advisory only —
  /// the backend interprets bytes via the OCR provider, not the extension.
  Future<ExtractedTenant> ocrExtract(
    Uint8List bytes, {
    String filename = 'nid.jpg',
  }) async {
    final form = FormData.fromMap(<String, dynamic>{
      'image': MultipartFile.fromBytes(bytes, filename: filename),
    });
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.tenantOcr,
        data: form,
      );
      return ExtractedTenant.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /tenants/voice` — upload a Bangla audio clip (multipart) for ASR
  /// extraction (T-006).
  ///
  /// Sends the raw [bytes] under the `audio` field (matching the backend
  /// `VoiceRequestSerializer.audio` FileField) and returns the same editable
  /// [ExtractedTenant] shape as OCR — **minus `photo_ref`**: voice has no stored
  /// artefact, so [ExtractedTenant.photoRef] degrades to an empty string. The
  /// review screen (T-011) is reused for confirmation. [filename] is advisory
  /// only — the ASR provider interprets the audio bytes, not the extension. The
  /// clip is uploaded then discarded; it is never persisted on the device.
  Future<ExtractedTenant> voiceExtract(
    Uint8List bytes, {
    String filename = 'voice.m4a',
  }) async {
    final form = FormData.fromMap(<String, dynamic>{
      'audio': MultipartFile.fromBytes(bytes, filename: filename),
    });
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.tenantVoice,
        data: form,
      );
      return ExtractedTenant.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  ApiException _asApiException(DioException e) {
    final err = e.error;
    return err is ApiException ? err : ApiException.fromDio(e);
  }
}
