import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/widgets/k_button.dart';
import '../../../../core/widgets/k_card.dart';
import '../../../../l10n/app_localizations.dart';

/// Temporary authenticated landing surface for EPIC-01. Proves the auth loop
/// end-to-end: a signed-in user reaches here, and the Logout button clears the
/// session (via the T-011 auth controller) which the router redirect bounces
/// back to `/auth/phone`.
///
// TODO(EPIC-02) role routing: replace `/home` with role-based routing to the
// landlord / manager / tenant shells (see 05_navigation_routing.md §1).
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  static const String routeName = 'home';
  static const String routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(KhatirSpacing.s6),
            child: KCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.common_app_name,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: KhatirSpacing.s3),
                  Text(
                    l10n.home_placeholder_welcome,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KhatirSpacing.s5),
                  KButton(
                    label: l10n.common_logout,
                    icon: Icons.logout,
                    // Logout clears the session; the router redirect (driven by
                    // AuthState via refreshListenable) returns to /auth/phone.
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).logout(),
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
