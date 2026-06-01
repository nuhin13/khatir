import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'sentry_init.dart';

/// Severity levels for [AppLogger]. ERROR is also reported to Sentry.
enum LogLevel { debug, info, warning, error }

/// Thin logging wrapper used across the app instead of `print`.
///
/// All messages are PII-masked (NID/OTP/token/secret/trx) before they reach
/// the console or Sentry (T-015 §15). ERROR-level logs are captured as Sentry
/// events when a DSN is configured; otherwise logging is local-only.
class AppLogger {
  const AppLogger(this.name);

  /// Logger name (typically the feature or class), e.g. `auth.login`.
  final String name;

  void debug(String message) => _log(LogLevel.debug, message);

  void info(String message) => _log(LogLevel.info, message);

  void warning(String message) => _log(LogLevel.warning, message);

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
    if (sentryEnabled) {
      Sentry.captureException(
        error ?? maskPii(message),
        stackTrace: stackTrace,
        hint: Hint.withMap({'logger': name, 'message': maskPii(message)}),
      );
    }
  }

  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final masked = maskPii(message);
    if (kDebugMode || level == LogLevel.error) {
      developer.log(
        masked,
        name: name,
        level: _severity(level),
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  int _severity(LogLevel level) => switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      };
}

// ── PII masking ─────────────────────────────────────────────────────────
// Mirrors the backend masking (khatir/core/logging.py): NID-like digit runs
// keep their last four digits; OTP/token/secret/trx values are masked whole.

final RegExp _nidRe = RegExp(r'(\d{6,13})(\d{4})\b');
final RegExp _bearerRe = RegExp(r'(?<=[Bb]earer\s)[A-Za-z0-9._\-]+');
final RegExp _sensitiveFieldRe = RegExp(
  r'''(["']?(?:otp|code|token|secret|password|api[_-]?key)["']?\s*[:=]\s*)(["']?)[^\s,;&}"']+''',
  caseSensitive: false,
);
final RegExp _trxRe = RegExp(
  r'''(["']?(?:trx|txn|trxid|trx_id|transaction_id)["']?\s*[:=]\s*)(["']?)[A-Za-z0-9]+''',
  caseSensitive: false,
);

const String _mask = '****';

/// Return [text] with NID/OTP/token/secret/trx patterns masked. Idempotent.
String maskPii(String text) {
  if (text.isEmpty) return text;
  var out = text;
  out = out.replaceAllMapped(_sensitiveFieldRe, (m) => '${m[1]}${m[2]}$_mask');
  out = out.replaceAllMapped(_trxRe, (m) => '${m[1]}${m[2]}$_mask');
  out = out.replaceAll(_bearerRe, _mask);
  out = out.replaceAllMapped(_nidRe, (m) => '$_mask${m[2]}');
  return out;
}
