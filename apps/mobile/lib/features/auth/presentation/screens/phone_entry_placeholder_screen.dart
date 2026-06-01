import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// Temporary destination for `/auth/phone` so onboarding can route onward
/// before T-009 builds the real phone-entry screen. Replaced in T-009.
class PhoneEntryPlaceholderScreen extends StatelessWidget {
  const PhoneEntryPlaceholderScreen({super.key});

  static const String routeName = 'auth-phone';
  static const String routePath = '/auth/phone';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(KhatirSpacing.s6),
            child: Text(
              l10n.common_app_name,
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
