import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/i18n/bangla_numerals.dart';
import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/widgets/k_button.dart';
import '../../../../core/widgets/k_card.dart';
import '../../../../core/widgets/k_chip.dart';
import '../../../../l10n/app_localizations.dart';

/// Routable placeholder shown after the splash. Demonstrates the Notun Din
/// theme + i18n end-to-end: a localized string, a locale toggle button, and
/// locale-aware numeral formatting — all themed from the shared tokens.
class PlaceholderScreen extends ConsumerWidget {
  const PlaceholderScreen({super.key});

  static const String routeName = 'placeholder';
  static const String routePath = '/placeholder';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final localeCode = ref.watch(localeProvider).languageCode;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(KhatirSpacing.s6),
            child: KCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.common_app_name, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: KhatirSpacing.s3),
                  Text(
                    l10n.placeholder_welcome,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KhatirSpacing.s4),
                  KChip(label: 'env: ${AppConfig.appEnv}'),
                  const SizedBox(height: KhatirSpacing.s3),
                  // Locale-aware numeral formatting demo.
                  Text(
                    BanglaNumerals.format(2026, localeCode),
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: KhatirSpacing.s5),
                  KButton(
                    label: l10n.common_toggle_language,
                    onPressed: () => ref.read(localeProvider.notifier).toggle(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
