import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/models.dart';
import '../../data/models/warning_enums.dart';
import '../../data/providers.dart';
import '../screens/warning_notice_screen.dart';
import '../screens/warning_screen.dart';

/// The warnings region on the unit/lease detail screen (EPIC-20 T-008).
///
/// Shows the landlord's issued warnings for [leaseId] (own only — server-side
/// `for_user` scoping ensures no cross-landlord data). Composition:
/// * Section heading "Warnings".
/// * List of issued warnings (type + date chip + "View notice" action).
/// * "Issue Warning" CTA at the bottom — **hidden** when [warningsEnabled] is
///   false (kill-switch off).
/// * Empty state when no warnings have been issued yet.
///
/// All colors/spacing/radius/fonts come from design tokens.
class LeaseWarningsSection extends ConsumerWidget {
  const LeaseWarningsSection({
    super.key,
    required this.leaseId,
    this.warningsEnabled = true,
  });

  /// The lease whose warnings are listed.
  final String leaseId;

  /// Whether the `warnings_feature` kill-switch is on.
  /// Pass `false` to hide the "Issue Warning" CTA (flag off).
  final bool warningsEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final warningsAsync = ref.watch(leaseWarningsProvider(leaseId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section heading ───────────────────────────────────────────────
        Text(
          l10n.unit_warnings_section.toUpperCase(),
          style: AppTextStyles.labelLarge.copyWith(
            color: KhatirColors.sageDk,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: KhatirSpacing.s3),

        // ── Warnings list ─────────────────────────────────────────────────
        warningsAsync.when(
          loading: () => const _LoadingCard(),
          error: (_, _) => _ErrorCard(
            onRetry: () =>
                ref.read(leaseWarningsProvider(leaseId).notifier).refresh(),
          ),
          data: (warnings) => warnings.isEmpty
              ? _EmptyState(l10n: l10n)
              : _WarningsList(
                  warnings: warnings,
                  l10n: l10n,
                  onViewNotice: (warningId) =>
                      _viewNotice(context, warningId),
                ),
        ),

        // ── Issue Warning CTA (hidden if kill-switch off) ─────────────────
        if (warningsEnabled) ...[
          const SizedBox(height: KhatirSpacing.s3),
          _IssueWarningButton(
            key: const ValueKey('leaseIssueWarningCta'),
            label: l10n.unit_issue_warning,
            onTap: () => _issueWarning(context),
          ),
        ],
      ],
    );
  }

  void _issueWarning(BuildContext context) {
    GoRouter.of(context).pushNamed(
      WarningScreen.routeName,
      pathParameters: {'id': leaseId},
    );
  }

  void _viewNotice(BuildContext context, String warningId) {
    GoRouter.of(context).pushNamed(
      WarningNoticeScreen.routeName,
      pathParameters: {'warningId': warningId},
    );
  }
}

// ── Private widgets ────────────────────────────────────────────────────────

/// A list of issued warning rows.
class _WarningsList extends StatelessWidget {
  const _WarningsList({
    required this.warnings,
    required this.l10n,
    required this.onViewNotice,
  });

  final List<Warning> warnings;
  final AppLocalizations l10n;
  final ValueChanged<String> onViewNotice;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Column(
        children: [
          for (int i = 0; i < warnings.length; i++) ...[
            _WarningRow(
              warning: warnings[i],
              l10n: l10n,
              onViewNotice: () => onViewNotice(warnings[i].id),
            ),
            if (i < warnings.length - 1)
              const Divider(height: 1, color: KhatirColors.line),
          ],
        ],
      ),
    );
  }
}

/// A single warning row: type + date on the left, "View notice" button.
class _WarningRow extends StatelessWidget {
  const _WarningRow({
    required this.warning,
    required this.l10n,
    required this.onViewNotice,
  });

  final Warning warning;
  final AppLocalizations l10n;
  final VoidCallback onViewNotice;

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final dateStr = _formatDate(warning.issuedAt, localeCode);
    final typeLabel = _typeLabel(l10n, warning.warningType);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s4,
        vertical: KhatirSpacing.s3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: KhatirColors.ink,
                  ),
                ),
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: KhatirColors.mutedDk),
                  ),
                ],
              ],
            ),
          ),
          // "View notice" only if the notice has been generated.
          if (warning.noticeRef.isNotEmpty)
            TextButton(
              onPressed: onViewNotice,
              style: TextButton.styleFrom(
                foregroundColor: KhatirColors.sageDk,
                textStyle: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w700),
                padding: const EdgeInsets.symmetric(
                  horizontal: KhatirSpacing.s2,
                ),
              ),
              child: Text(l10n.warning_view_notice),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt, String localeCode) {
    if (dt == null) return '';
    // Use simple ISO-ish format to avoid importing intl directly here.
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

/// Empty state when no warnings have been issued yet for this lease.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Text(
        l10n.unit_warnings_empty,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.mutedDk),
      ),
    );
  }
}

/// Short inline loading placeholder while warnings are being fetched.
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

/// Error card with a retry option.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 16, color: KhatirColors.mutedDk),
          const SizedBox(width: KhatirSpacing.s2),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Full-width "Issue Warning" CTA — sage-tinted with a warning icon.
class _IssueWarningButton extends StatelessWidget {
  const _IssueWarningButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.button);
    return Material(
      color: KhatirColors.butterBg,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 16, color: KhatirColors.butterDk),
              const SizedBox(width: KhatirSpacing.s2),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: KhatirColors.butterDk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Localised display label for a [WarningType].
String _typeLabel(AppLocalizations l10n, WarningType type) => switch (type) {
      WarningType.lateRent => l10n.warning_type_late_rent,
      WarningType.leaseViolation => l10n.warning_type_lease_violation,
      WarningType.noise => l10n.warning_type_noise,
      WarningType.propertyDamage => l10n.warning_type_property_damage,
      WarningType.other => l10n.warning_type_other,
    };
