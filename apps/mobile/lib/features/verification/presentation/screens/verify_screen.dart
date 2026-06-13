import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/config/flags_provider.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../billing/presentation/widgets/upgrade_prompt.dart';
import '../../data/models/verification_result.dart';
import '../../data/verification_providers.dart';

/// NID verify screen (EPIC-17 T-006), mirroring the `verify` prototype
/// (`proto/screens-landlord2.js` → `reg('verify')`).
///
/// Composition (top to bottom):
/// * **App bar** — "NID যাচাই · Verify" with back.
/// * **Emoji hero** — 🛡️ + "Let's verify" handwritten accent.
/// * **Info card** — neutral EC-verification description, consent row.
/// * **Consent checkbox** — landlord attests tenant permission (required).
/// * **Verify button** — disabled until consent is checked.
/// * **Result state** — Matched (green) / Not Matched (amber) / Error.
/// * **Flag-off gate** — unavailable message when `nid_verification_enabled` is off.
/// * **Tier gate** — upgrade prompt for free-tier users.
///
/// States:
///   idle (consent)  → loading → matched / not_matched / error / failure
///   flag-off gate
///   tier-gated upgrade prompt
///
/// **Privacy rule enforced**: never display or log any raw EC field.
/// Only `matched / not matched / error` is shown.
///
/// All colors/spacing/radii come from the design tokens.
class VerifyScreen extends HookConsumerWidget {
  const VerifyScreen({super.key, required this.tenantId});

  /// The Khatir tenant id to verify.
  final String tenantId;

  static const String routePath = '/tenants/:id/verify';
  static const String routeName = 'tenantVerify';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Feature flag gate.
    final flagEnabled = ref
        .watch(flagsProvider)
        .isEnabled('nid_verification_enabled', orElse: false);

    // Tier gate: free users cannot access NID verification.
    // The `nid_verification_tier_allowed` flag is set to false for free-tier
    // users by the backend config (flagged off until they upgrade).
    final isTierGated = !ref
        .watch(flagsProvider)
        .isEnabled('nid_verification_tier_allowed', orElse: true);

    // Consent checkbox state.
    final consentGiven = useState<bool>(false);

    // Verify controller — keyed by tenantId.
    final verifyAsync = ref.watch(verifyControllerProvider(tenantId));

    // ── Flag-off gate ──────────────────────────────────────────────────────
    if (!flagEnabled) {
      return Scaffold(
        backgroundColor: KhatirColors.cream,
        appBar: _appBar(context, l10n),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(KhatirSpacing.s5),
            child: _InfoCard(
              key: const ValueKey('verifyFlagOff'),
              icon: const Text('🔒', style: TextStyle(fontSize: 32)),
              body: l10n.nid_verify_flag_off,
              color: KhatirColors.butterBg,
              textColor: KhatirColors.mutedDk,
            ),
          ),
        ),
      );
    }

    // ── Tier-gated upgrade prompt ──────────────────────────────────────────
    if (isTierGated) {
      return Scaffold(
        backgroundColor: KhatirColors.cream,
        appBar: _appBar(context, l10n),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(KhatirSpacing.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoCard(
                  key: const ValueKey('verifyTierGated'),
                  icon: const Text('🔒', style: TextStyle(fontSize: 32)),
                  body: l10n.nid_verify_upgrade,
                  color: KhatirColors.roseBg,
                  textColor: KhatirColors.roseDk,
                ),
                const SizedBox(height: KhatirSpacing.s4),
                FilledButton(
                  key: const ValueKey('verifyUpgradeBtn'),
                  style: FilledButton.styleFrom(
                    backgroundColor: KhatirColors.sage,
                    foregroundColor: KhatirColors.card,
                    padding: const EdgeInsets.symmetric(
                        vertical: KhatirSpacing.s4),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(KhatirRadius.button),
                    ),
                  ),
                  onPressed: () => UpgradePrompt.show(context),
                  child: Text(
                    l10n.upgrade_cta,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Normal verify flow ─────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: _appBar(context, l10n),
      body: SafeArea(
        top: false,
        child: verifyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _FailureBody(message: e.toString(), l10n: l10n),
          data: (state) {
            return switch (state) {
              VerifyIdle() => _ConsentBody(
                  key: const ValueKey('verifyIdle'),
                  tenantId: tenantId,
                  consentGiven: consentGiven,
                  l10n: l10n,
                ),
              VerifyLoading() => _LoadingBody(l10n: l10n),
              VerifyDone(:final result) => _ResultBody(
                  key: ValueKey('verifyResult_${result.status.wire}'),
                  result: result,
                  l10n: l10n,
                  onRetry: () {
                    // Reset to idle so the user can consent and retry.
                    consentGiven.value = false;
                    ref
                        .read(verifyControllerProvider(tenantId).notifier)
                        .resetToIdle();
                  },
                ),
              VerifyFailure(:final message) => _FailureBody(
                  message: message,
                  l10n: l10n,
                ),
            };
          },
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context, AppLocalizations l10n) => AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.nid_verify_title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      );
}

// ── Consent body ─────────────────────────────────────────────────────────────

class _ConsentBody extends HookConsumerWidget {
  const _ConsentBody({
    super.key,
    required this.tenantId,
    required this.consentGiven,
    required this.l10n,
  });

  final String tenantId;
  final ValueNotifier<bool> consentGiven;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(verifyControllerProvider(tenantId)).isLoading;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s5,
        KhatirSpacing.s2,
        KhatirSpacing.s5,
        KhatirSpacing.s6,
      ),
      children: [
        // Emoji hero.
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: KhatirSpacing.s4),
            const Text('🛡️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: KhatirSpacing.s2),
            Text(
              l10n.nid_verify_hero,
              style: AppTextStyles.accent.copyWith(fontSize: 28),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: KhatirSpacing.s5),
        // Info card: EC description + consent row.
        _VerifyInfoCard(
          description: l10n.nid_verify_desc,
          consentLabel: l10n.nid_verify_consent,
          consentGiven: consentGiven.value,
          onConsentChanged: busy
              ? null
              : (v) => consentGiven.value = v ?? false,
        ),
        const SizedBox(height: KhatirSpacing.s5),
        // Verify button.
        FilledButton(
          key: const ValueKey('verifyRunBtn'),
          style: FilledButton.styleFrom(
            backgroundColor: consentGiven.value
                ? KhatirColors.sage
                : KhatirColors.muted,
            foregroundColor: KhatirColors.card,
            padding:
                const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(KhatirRadius.button),
            ),
          ),
          onPressed: (consentGiven.value && !busy)
              ? () => ref
                    .read(verifyControllerProvider(tenantId).notifier)
                    .run(consent: true)
              : null,
          child: Text(
            l10n.nid_verify_run,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// ── Loading body ─────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('verifyLoading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛡️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: KhatirSpacing.s4),
          Text(
            l10n.nid_verify_loading,
            style: AppTextStyles.accent.copyWith(
              fontSize: 22,
              color: KhatirColors.muted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KhatirSpacing.s5),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
}

// ── Result body ──────────────────────────────────────────────────────────────

class _ResultBody extends StatelessWidget {
  const _ResultBody({
    super.key,
    required this.result,
    required this.l10n,
    required this.onRetry,
  });

  final VerificationResult result;
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s5,
        KhatirSpacing.s2,
        KhatirSpacing.s5,
        KhatirSpacing.s6,
      ),
      children: [
        const SizedBox(height: KhatirSpacing.s4),
        _ResultBadge(result: result, l10n: l10n),
        const SizedBox(height: KhatirSpacing.s5),
        if (result.status == VerificationResultStatus.error ||
            result.status == VerificationResultStatus.notMatched)
          OutlinedButton(
            key: const ValueKey('verifyRetryBtn'),
            style: OutlinedButton.styleFrom(
              foregroundColor: KhatirColors.ink,
              side: const BorderSide(color: KhatirColors.lineDk),
              padding:
                  const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(KhatirRadius.button),
              ),
            ),
            onPressed: onRetry,
            child: Text(l10n.nid_verify_retry),
          ),
        if (result.status == VerificationResultStatus.matched) ...[
          FilledButton(
            key: const ValueKey('verifyDoneBtn'),
            style: FilledButton.styleFrom(
              backgroundColor: KhatirColors.sage,
              foregroundColor: KhatirColors.card,
              padding:
                  const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(KhatirRadius.button),
              ),
            ),
            onPressed: () => context.pop(),
            child: Text(
              l10n.nid_verify_done,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Failure body ──────────────────────────────────────────────────────────────

class _FailureBody extends StatelessWidget {
  const _FailureBody({required this.message, required this.l10n});

  final String message;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('verifyFailure'),
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoCard(
              icon: const Text('⚠️', style: TextStyle(fontSize: 32)),
              body: l10n.nid_verify_error,
              color: KhatirColors.dangerBg,
              textColor: KhatirColors.danger,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Result badge ─────────────────────────────────────────────────────────────

/// Shows the verification outcome as a large badge card.
/// **Privacy rule**: only matched/not_matched/error is displayed.
class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.result, required this.l10n});

  final VerificationResult result;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (emoji, title, sub, bg, textC) = switch (result.status) {
      VerificationResultStatus.matched => (
          '🎉',
          l10n.nid_verify_matched,
          l10n.nid_verify_matched_sub,
          KhatirColors.sageBg,
          KhatirColors.sageDk,
        ),
      VerificationResultStatus.notMatched => (
          '⚠️',
          l10n.nid_verify_not_matched,
          l10n.nid_verify_not_matched_sub,
          KhatirColors.butterBg,
          KhatirColors.butterDk,
        ),
      VerificationResultStatus.error => (
          '❌',
          l10n.nid_verify_error,
          l10n.nid_verify_error_sub,
          KhatirColors.dangerBg,
          KhatirColors.danger,
        ),
    };

    return Container(
      key: ValueKey('verifyResultBadge_${result.status.wire}'),
      padding: const EdgeInsets.all(KhatirSpacing.s5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: KhatirSpacing.s3),
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: textC,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KhatirSpacing.s1),
          Text(
            sub,
            style:
                AppTextStyles.bodyMedium.copyWith(color: KhatirColors.mutedDk),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Verify info card (consent + description) ─────────────────────────────────

class _VerifyInfoCard extends StatelessWidget {
  const _VerifyInfoCard({
    required this.description,
    required this.consentLabel,
    required this.consentGiven,
    required this.onConsentChanged,
  });

  final String description;
  final String consentLabel;
  final bool consentGiven;
  final ValueChanged<bool?>? onConsentChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
          ),
          const SizedBox(height: KhatirSpacing.s3),
          GestureDetector(
            onTap: onConsentChanged == null
                ? null
                : () => onConsentChanged!(!consentGiven),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KhatirSpacing.s3,
                vertical: KhatirSpacing.s2,
              ),
              decoration: BoxDecoration(
                color: consentGiven
                    ? KhatirColors.sageBg
                    : KhatirColors.butterBg,
                borderRadius: BorderRadius.circular(KhatirRadius.sm),
              ),
              child: Row(
                children: [
                  Checkbox(
                    key: const ValueKey('verifyConsentCheckbox'),
                    value: consentGiven,
                    onChanged: onConsentChanged,
                    activeColor: KhatirColors.sage,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: KhatirSpacing.s2),
                  Expanded(
                    child: Text(
                      consentLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: KhatirColors.mutedDk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generic info card ────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    super.key,
    required this.icon,
    required this.body,
    required this.color,
    required this.textColor,
  });

  final Widget icon;
  final String body;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: KhatirSpacing.s3),
          Expanded(
            child: Text(
              body,
              style: AppTextStyles.bodyMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
