import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/warning_enums.dart';
import '../../data/providers.dart';
import 'warning_notice_screen.dart';

/// The issue-warning screen (EPIC-20 T-005), reached at `/lease/:id/warning`.
/// Mirroring the `warning` screen design prototype.
///
/// Lets a landlord issue a **private** formal warning to their own tenant:
/// - Type picker (late_rent / lease_violation / noise / property_damage / other)
/// - Free-text reason
/// - Prominent "private between you and your tenant" banner + legal disclaimer
/// - Kill-switch off → screen shows a "feature unavailable" message
///
/// On submit the warning is issued (server-side), then the screen offers to
/// navigate to the notice PDF generator (T-006). All colors/spacing/radius/fonts
/// come from design tokens. No prototype hex/px is hardcoded.
class WarningScreen extends HookConsumerWidget {
  const WarningScreen({
    super.key,
    required this.leaseId,
    this.warningsEnabled = true,
    this.onIssued,
  });

  /// The lease for which this warning is issued.
  final String leaseId;

  /// Whether the `warnings_feature` kill-switch is on.
  /// Defaults to `true`; pass `false` in widget tests to simulate flag-off.
  final bool warningsEnabled;

  /// Optional test seam: called after a warning is issued (instead of routing
  /// to the notice screen).
  final void Function(String warningId)? onIssued;

  static const String routePath = '/lease/:id/warning';
  static const String routeName = 'issueWarning';

  /// Typed path for use in `GoRouter.pushNamed`.
  static String pathFor(String leaseId) => '/lease/$leaseId/warning';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Kill-switch off → show unavailable state immediately.
    if (!warningsEnabled) {
      return Scaffold(
        backgroundColor: KhatirColors.cream,
        appBar: _appBar(l10n),
        body: SafeArea(
          top: false,
          child: _FeatureDisabledState(l10n: l10n),
        ),
      );
    }

    final selectedType = useState<WarningType>(WarningType.lateRent);
    final reasonCtrl = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);

    final issueAsync = ref.watch(issueWarningProvider(leaseId));
    final isSubmitting = issueAsync.isLoading;

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: _appBar(l10n),
      body: SafeArea(
        top: false,
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              KhatirSpacing.s5,
              KhatirSpacing.s4,
              KhatirSpacing.s5,
              KhatirSpacing.s6,
            ),
            children: [
              // ── Privacy banner ──────────────────────────────────────────
              _PrivacyBanner(l10n: l10n),
              const SizedBox(height: KhatirSpacing.s4),

              // ── Type picker ─────────────────────────────────────────────
              _SectionLabel(text: l10n.warning_type_label),
              const SizedBox(height: KhatirSpacing.s3),
              _TypePicker(
                selected: selectedType.value,
                onChanged: (t) => selectedType.value = t,
                l10n: l10n,
              ),
              const SizedBox(height: KhatirSpacing.s4),

              // ── Reason ──────────────────────────────────────────────────
              _SectionLabel(text: l10n.warning_reason_label),
              const SizedBox(height: KhatirSpacing.s3),
              TextFormField(
                key: const ValueKey('warningReasonField'),
                controller: reasonCtrl,
                maxLines: 4,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: l10n.warning_reason_hint,
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: KhatirColors.mutedDk),
                  filled: true,
                  fillColor: KhatirColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KhatirRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(KhatirSpacing.s4),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.warning_reason_required
                    : null,
              ),
              const SizedBox(height: KhatirSpacing.s4),

              // ── Legal disclaimer ─────────────────────────────────────────
              _DisclaimerCard(l10n: l10n),
              const SizedBox(height: KhatirSpacing.s6),

              // ── Submit ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const ValueKey('warningIssueButton'),
                  onPressed: isSubmitting
                      ? null
                      : () => _submit(
                            context,
                            ref,
                            formKey,
                            selectedType.value,
                            reasonCtrl.text,
                            l10n,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KhatirColors.sage,
                    foregroundColor: KhatirColors.cream,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: KhatirSpacing.s4,
                    ),
                    textStyle: AppTextStyles.labelLarge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(KhatirRadius.button),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: KhatirColors.cream,
                          ),
                        )
                      : Text(l10n.warning_issue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar(AppLocalizations l10n) => AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.warning_screen_title,
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      );

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    GlobalKey<FormState> formKey,
    WarningType type,
    String reason,
    AppLocalizations l10n,
  ) async {
    if (!formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final warning = await ref
          .read(issueWarningProvider(leaseId).notifier)
          .issue(warningType: type, reason: reason.trim());
      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.warning_issued_ok)));
      // Navigate to notice PDF screen, or call test seam.
      if (onIssued != null) {
        onIssued!(warning.id);
      } else {
        GoRouter.of(context).pushNamed(
          WarningNoticeScreen.routeName,
          pathParameters: {'warningId': warning.id},
        );
      }
    } on ApiException {
      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.warning_issue_error)));
    } catch (_) {
      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.warning_issue_error)));
    }
  }
}

/// The prominent privacy banner at the top of the warning form.
class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.tile),
        border: Border.all(color: KhatirColors.sage),
      ),
      child: Text(
        l10n.warning_private_notice,
        style: AppTextStyles.bodyMedium.copyWith(
          color: KhatirColors.sageDk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Warning type picker as a column of selectable cards.
class _TypePicker extends StatelessWidget {
  const _TypePicker({
    required this.selected,
    required this.onChanged,
    required this.l10n,
  });

  final WarningType selected;
  final ValueChanged<WarningType> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: WarningType.values.map((type) {
        final isSelected = type == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: KhatirSpacing.s2),
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: KhatirSpacing.s4,
                vertical: KhatirSpacing.s3,
              ),
              decoration: BoxDecoration(
                color: isSelected ? KhatirColors.sageBg : KhatirColors.card,
                borderRadius: BorderRadius.circular(KhatirRadius.tile),
                border: Border.all(
                  color: isSelected ? KhatirColors.sage : KhatirColors.line,
                ),
              ),
              child: Text(
                _typeLabel(l10n, type),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? KhatirColors.sageDk : KhatirColors.ink,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// The legal disclaimer card below the form.
class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.butterBg,
        borderRadius: BorderRadius.circular(KhatirRadius.tile),
        border: Border.all(color: KhatirColors.butter),
      ),
      child: Text(
        l10n.warning_disclaimer,
        style: AppTextStyles.bodySmall.copyWith(
          color: KhatirColors.ink,
        ),
      ),
    );
  }
}

/// Feature-disabled state when the kill-switch is off.
class _FeatureDisabledState extends StatelessWidget {
  const _FeatureDisabledState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Text(
          l10n.warning_feature_disabled,
          textAlign: TextAlign.center,
          style:
              AppTextStyles.bodyMedium.copyWith(color: KhatirColors.mutedDk),
        ),
      ),
    );
  }
}

/// Small uppercase section heading.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelLarge.copyWith(
        color: KhatirColors.sageDk,
        fontWeight: FontWeight.w800,
        fontSize: 12,
        letterSpacing: 0.5,
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
