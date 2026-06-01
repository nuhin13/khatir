import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/router/args/auth_args.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// Temporary destination for `/auth/otp` so phone-entry (T-009) can route
/// onward before T-010 builds the real OTP-verification screen. Reads the
/// typed [AuthArgs.phone] so the navigation contract is exercised end to end.
class OtpEntryPlaceholderScreen extends StatelessWidget {
  const OtpEntryPlaceholderScreen({super.key, this.args});

  final AuthArgs? args;

  static const String routeName = 'auth-otp';
  static const String routePath = '/auth/otp';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: KhatirColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(KhatirSpacing.s6),
            child: Text(
              args?.phone ?? l10n.common_app_name,
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
