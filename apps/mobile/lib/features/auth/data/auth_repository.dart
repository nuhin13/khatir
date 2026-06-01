import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/request_otp_request.dart';
import 'models/request_otp_response.dart';

/// Phone normalisation helper: turns a BD local number into E.164.
///
/// `01711000111` → `+8801711000111`. Already-prefixed values are left intact.
/// Separators (spaces, dashes) are stripped before formatting.
String normaliseBdPhone(String raw) {
  final digitsAndPlus = raw.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digitsAndPlus.startsWith('+880')) return digitsAndPlus;
  if (digitsAndPlus.startsWith('880')) return '+$digitsAndPlus';
  // Local form 01XXXXXXXXX → drop the leading 0, prefix +880.
  if (digitsAndPlus.startsWith('0')) {
    return '+880${digitsAndPlus.substring(1)}';
  }
  return '+880$digitsAndPlus';
}

/// Network access for the auth feature. Currently only the request-otp call
/// (T-009); verify-otp lands in T-010.
class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  /// Requests an OTP for [phone]. [phone] should already be E.164-normalised.
  ///
  /// Throws [ApiException] (normalised by the dio error interceptor) on
  /// failure so callers can branch on [ApiException.statusCode].
  Future<RequestOtpResponse> requestOtp(String phone) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.requestOtp,
        data: RequestOtpRequest(phone: phone).toJson(),
      );
      final data = res.data ?? const <String, dynamic>{};
      return RequestOtpResponse.fromJson(data);
    } on DioException catch (e) {
      final err = e.error;
      throw err is ApiException ? err : ApiException.fromDio(e);
    }
  }
}
