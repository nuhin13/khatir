import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/i18n/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

/// Root widget. Wires go_router, the token-driven Notun Din theme, and
/// gen-l10n internationalization (bn default, en toggle).
class KhatirApp extends ConsumerWidget {
  const KhatirApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).common_app_name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
