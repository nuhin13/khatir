import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// Placeholder DMP-form destination for the add-tenant flow (EPIC-04 T-016).
///
/// All three intake paths (OCR / voice / manual) converge on the shared save
/// action, which — on a successful tenant create — routes here at
/// `/dmpform/{tenantId}`. The real DMP (police) form is built in EPIC-05; until
/// then this screen confirms the tenant was saved and stands in for that route
/// so the EPIC-04 flow is wired end-to-end.
///
/// All colors/spacing/radii/fonts come from the design tokens.
class DmpPlaceholderScreen extends StatelessWidget {
  const DmpPlaceholderScreen({super.key, required this.tenantId});

  /// The id of the tenant that was just created — the DMP form (EPIC-05) is
  /// generated for this tenant.
  final String tenantId;

  /// `/dmpform/{tenantId}` — the convergent success destination of the
  /// add-tenant flow. Registered on the root navigator so it covers the shell.
  static const String routeName = 'dmpForm';
  static String pathFor(String tenantId) => '/dmpform/$tenantId';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.dmp_placeholder_title,
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(KhatirSpacing.s6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('✅', style: TextStyle(fontSize: 56)),
                const SizedBox(height: KhatirSpacing.s4),
                Text(
                  l10n.dmp_placeholder_heading,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: KhatirColors.sageDk,
                  ),
                ),
                const SizedBox(height: KhatirSpacing.s2),
                Text(
                  l10n.dmp_placeholder_body,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: KhatirColors.mutedDk,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
