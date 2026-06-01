import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import 'core/router/app_router.dart';

/// Root widget. Wires go_router and a minimal theme seeded from the shared
/// Notun Din design tokens. The full theme + i18n (gen-l10n) land in T-008.
class KhatirApp extends ConsumerWidget {
  const KhatirApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Khatir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Seeded from shared design tokens — no inline hex. Full token-driven
        // theme is built in T-008.
        colorScheme: ColorScheme.fromSeed(
          seedColor: KhatirColors.sage,
          surface: KhatirColors.cream,
        ),
        scaffoldBackgroundColor: KhatirColors.cream,
      ),
      routerConfig: router,
    );
  }
}
