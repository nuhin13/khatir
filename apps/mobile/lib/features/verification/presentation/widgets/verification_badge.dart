import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../tenants/data/models/tenant_enums.dart';

/// A compact chip badge showing a tenant's NID verification status.
///
/// Three visual states, all values from design tokens:
///   • [VerificationStatus.matched] → green (sageBg / sageDk) — "Verified"
///   • [VerificationStatus.unverified] → grey (line / mutedDk) — "Unverified"
///   • [VerificationStatus.notMatched] / [VerificationStatus.error]
///     → amber (butterBg / butterDk) — "Failed"
///
/// Optionally tappable: when [onTap] is provided the chip renders with a slight
/// ink-ripple border so users can navigate to the verify screen.
///
/// Privacy rule: the badge shows ONLY the outcome label — never any raw EC field.
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({
    super.key,
    required this.status,
    this.onTap,
  });

  /// The tenant's verification status (from [Tenant.verificationStatus]).
  final VerificationStatus status;

  /// Optional tap callback — e.g. navigate to the verify screen.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, bg, textC) = _resolve(l10n, status);

    final badge = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s3,
        vertical: KhatirSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(KhatirRadius.chip),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: textC,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (onTap == null) return badge;

    return GestureDetector(
      key: const ValueKey('verificationBadgeTap'),
      onTap: onTap,
      child: badge,
    );
  }

  static (String, Color, Color) _resolve(
    AppLocalizations l10n,
    VerificationStatus status,
  ) =>
      switch (status) {
        VerificationStatus.matched => (
            l10n.nid_badge_verified,
            KhatirColors.sageBg,
            KhatirColors.sageDk,
          ),
        VerificationStatus.unverified => (
            l10n.nid_badge_unverified,
            KhatirColors.line,
            KhatirColors.mutedDk,
          ),
        VerificationStatus.notMatched || VerificationStatus.error => (
            l10n.nid_badge_failed,
            KhatirColors.butterBg,
            KhatirColors.butterDk,
          ),
      };
}
