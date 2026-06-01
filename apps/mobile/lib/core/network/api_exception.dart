import 'package:dio/dio.dart';

/// Normalised exception surfaced from the network layer so presentation code
/// never has to reason about raw [DioException]s.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.cause,
  });

  /// Human-readable (non-localised) message for logging/debugging.
  final String message;

  /// HTTP status code, when the failure carried a response.
  final int? statusCode;

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
    return ApiException(message: message, statusCode: status, cause: e);
  }

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}
