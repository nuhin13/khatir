import 'package:dio/dio.dart';

/// Normalised exception surfaced from the network layer so presentation code
/// never has to reason about raw [DioException]s.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.cause,
  });

  /// Human-readable (non-localised) message for logging/debugging.
  final String message;

  /// HTTP status code, when the failure carried a response.
  final int? statusCode;

  /// Stable machine code lifted from the API error envelope
  /// (`{"error": {"code": "...", ...}}`, see backend `core/exceptions.py`).
  /// Lets presentation code branch on a specific failure (e.g.
  /// `tier_limit_exceeded` → upgrade prompt) without parsing messages. Null when
  /// the failure carried no envelope (timeout, connection error, …).
  final String? errorCode;

  /// The originating error, if any.
  final Object? cause;

  /// Builds an [ApiException] from a [DioException].
  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final message = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Network timeout',
      DioExceptionType.connectionError => 'Connection error',
      DioExceptionType.badResponse => 'Request failed (HTTP $status)',
      DioExceptionType.cancel => 'Request cancelled',
      _ => 'Unexpected network error',
    };
    return ApiException(
      message: message,
      statusCode: status,
      errorCode: _codeFromEnvelope(e.response?.data),
      cause: e,
    );
  }

  /// Extracts the `error.code` string from a standard API error envelope, or
  /// null when [data] is not the expected `{"error": {"code": "..."}}` shape.
  static String? _codeFromEnvelope(Object? data) {
    if (data is! Map) return null;
    final error = data['error'];
    if (error is! Map) return null;
    final code = error['code'];
    return code is String ? code : null;
  }

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, errorCode: $errorCode, '
      'message: $message)';
}
