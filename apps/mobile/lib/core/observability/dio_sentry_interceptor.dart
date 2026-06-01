import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'logger.dart';
import 'sentry_init.dart';

/// Reports non-2xx Dio responses and transport errors to Sentry, PII-safe.
///
/// Only the request method, masked path, and status code are attached — never
/// request/response bodies (which may contain NID/OTP/token payloads) and never
/// the `Authorization` header (T-015 §3, §15). A no-op when no DSN is set.
class DioSentryInterceptor extends Interceptor {
  const DioSentryInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (sentryEnabled) {
      final status = err.response?.statusCode;
      final data = <String, dynamic>{
        'http.method': err.requestOptions.method,
        'http.path': maskPii(err.requestOptions.path),
      };
      if (status != null) {
        data['http.status'] = status;
      }
      Sentry.captureException(err, hint: Hint.withMap(data));
    }
    handler.next(err);
  }
}
