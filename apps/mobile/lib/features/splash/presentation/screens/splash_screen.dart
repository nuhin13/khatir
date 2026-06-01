import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// Branded splash. Reading [authControllerProvider] kicks off the session
/// bootstrap (its `build()` resolves persisted tokens via `/auth/me`); while
/// auth state is `unknown` the router keeps the user here. The redirect in
/// `app_router.dart` then routes onward (onboarding / phone / home) once
/// bootstrap resolves. Mirrors the `splash` prototype; values from tokens.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  static const String routeName = 'splash';
  static const String routePath = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subscribing here ensures bootstrap is kicked off as soon as the splash
    // mounts; the router redirect reacts to the resolved AuthState.
    ref.watch(authControllerProvider);

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.common_app_name,
                style: AppTextStyles.displayLarge.copyWith(
                  color: KhatirColors.ink,
                ),
              ),
              const SizedBox(height: KhatirSpacing.s2),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: KhatirColors.butter,
                  borderRadius: BorderRadius.circular(KhatirRadius.pill),
                ),
              ),
              const SizedBox(height: KhatirSpacing.s6),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: KhatirColors.sage,
                ),
              ),
              const SizedBox(height: KhatirSpacing.s4),
              Text(
                l10n.splash_loading,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: KhatirColors.mutedDk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
