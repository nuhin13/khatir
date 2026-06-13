import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../screens/plan_screen.dart';

/// A friendly upgrade bottom sheet (EPIC-10 T-008) shown when a free-tier
/// landlord hits their tenant allowance — i.e. the add-tenant call comes back
/// with the `tier_limit_exceeded` envelope. It explains the limit and offers two
/// actions: **Upgrade plan** (routes to `/settings/plan`) or **Not now**
/// (dismiss).
///
/// Surface it through [UpgradePrompt.show], which presents it as a modal bottom
/// sheet and resolves to `true` when the caller should navigate on to the plan
/// screen. Colours, spacing, radii and fonts all come from the shared design
/// tokens — nothing is hardcoded.
class UpgradePrompt extends StatelessWidget {
  const UpgradePrompt({super.key});

  /// Presents the prompt as a modal bottom sheet. On **Upgrade plan** it pushes
  /// the plan screen (`/settings/plan`) before closing; **Not now** / scrim tap
  /// simply dismisses. Returns `true` when the user chose to upgrade.
  static Future<bool> show(BuildContext context) async {
    final chose = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UpgradePrompt(),
    );
    return chose ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('upgradePrompt'),
        margin: const EdgeInsets.all(KhatirSpacing.s3),
        padding: const EdgeInsets.all(KhatirSpacing.s5),
        decoration: BoxDecoration(
          color: KhatirColors.card,
          borderRadius: BorderRadius.circular(KhatirRadius.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle.
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KhatirColors.lineDk,
                  borderRadius: BorderRadius.circular(KhatirRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: KhatirSpacing.s5),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: KhatirColors.butterBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_outlined,
                color: KhatirColors.butterDk,
              ),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            Text(
              l10n.upgrade_title,
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: KhatirSpacing.s2),
            Text(
              l10n.upgrade_body,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: KhatirColors.mutedDk),
            ),
            const SizedBox(height: KhatirSpacing.s5),
            FilledButton(
              key: const ValueKey('upgradePromptUpgrade'),
              style: FilledButton.styleFrom(
                backgroundColor: KhatirColors.sage,
                foregroundColor: KhatirColors.card,
                padding:
                    const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KhatirRadius.button),
                ),
              ),
              onPressed: () {
                // Close the sheet first, then route so the plan screen is not
                // pushed under a still-open scrim.
                Navigator.of(context).pop(true);
                GoRouter.of(context).pushNamed(PlanScreen.routeName);
              },
              child: Text(
                l10n.upgrade_cta,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: KhatirSpacing.s2),
            TextButton(
              key: const ValueKey('upgradePromptLater'),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.upgrade_later,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: KhatirColors.mutedDk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
