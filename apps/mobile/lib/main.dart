import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app.dart';
import 'core/observability/sentry_init.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialise observability (Sentry) before runApp; a no-op when no DSN is
  // configured, so the app still starts without an account (T-015).
  initObservability(() {
    runApp(
      const ProviderScope(
        child: KhatirApp(),
      ),
    );
  });
}
