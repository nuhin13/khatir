import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/app_config.dart';

/// Sentry DSN sourced from `--dart-define=SENTRY_DSN=...`. Empty by default so
/// observability is a graceful no-op when no DSN is configured (T-015 §3, §13).
const String _sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

/// Whether a Sentry DSN has been provided at build time.
bool get sentryEnabled => _sentryDsn.isNotEmpty;

/// Initialise Sentry (if a DSN is set) and run [appRunner].
///
/// When no DSN is configured this simply runs [appRunner] directly, so the app
/// starts and works without any Sentry account. When a DSN is present, the SDK
/// is initialised with the environment tag (dev/staging/prod) and a modest
/// traces sample rate, then unhandled errors are reported automatically.
Future<void> initObservability(FutureOr<void> Function() appRunner) async {
  if (!sentryEnabled) {
    await appRunner();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      options.environment = AppConfig.appEnv;
      // Keep tracing cost low (T-015 §15).
      options.tracesSampleRate = 0.1;
      // Never attach PII (NID/OTP/token payloads) to Sentry events.
      options.sendDefaultPii = false;
      options.debug = kDebugMode;
    },
    appRunner: appRunner,
  );
}
