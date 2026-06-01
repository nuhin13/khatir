import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/router/args/auth_args.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/phone_form_controller.dart';
import '../controllers/request_otp_controller.dart';

/// Phone-entry screen — mirrors the `login` prototype (screens-onboard.js).
///
/// Hero greeting, sign-in subtitle, a BD phone field (`🇧🇩 +88` prefix,
/// 11-digit local input), a Send-code button with loading state, a WhatsApp
/// note and a testimonial card. On a successful `request-otp` it routes to
/// `/auth/otp` with a typed [AuthArgs]. All visual values come from tokens.
class PhoneEntryScreen extends ConsumerWidget {
  const PhoneEntryScreen({super.key});

  static const String routeName = 'auth-phone';
  static const String routePath = '/auth/phone';

  /// Destination after a successful request (real screen lands in T-010).
  static const String otpRoutePath = '/auth/otp';

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    FocusScope.of(context).unfocus();
    final phone = ref.read(phoneFormControllerProvider);
    final normalised =
        await ref.read(requestOtpControllerProvider.notifier).requestOtp(phone);
    if (normalised == null || !context.mounted) return;
    context.push(otpRoutePath, extra: AuthArgs(phone: normalised));
  }

  String? _errorText(AppLocalizations l10n, Object error) {
    if (error is RequestOtpFailure) {
      return switch (error.kind) {
        RequestOtpError.rateLimited => l10n.auth_rate_limited,
        RequestOtpError.network => l10n.common_network_error,
      };
    }
    return l10n.common_network_error;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isValid = ref.watch(phoneValidProvider);
    final requestState = ref.watch(requestOtpControllerProvider);
    final isSubmitting = requestState.isLoading;

    final requestError = requestState.maybeWhen(
      error: (e, _) => _errorText(l10n, e),
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            KhatirSpacing.s6,
            KhatirSpacing.s6,
            KhatirSpacing.s6,
            KhatirSpacing.s7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero greeting.
              Text(
                '👋',
                textAlign: TextAlign.center,
                style: AppTextStyles.displayLarge.copyWith(fontSize: 48),
              ),
              const SizedBox(height: KhatirSpacing.s2),
              Text(
                l10n.auth_phone_hero,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: KhatirSpacing.s1),
              Text(
                l10n.auth_phone_title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: KhatirColors.muted,
                ),
              ),
              const SizedBox(height: KhatirSpacing.s5),
              // Phone field: 🇧🇩 +88 · divider · 11-digit input.
              _PhoneField(
                enabled: !isSubmitting,
                hasError: requestError != null,
                errorText: requestError,
                onSubmit: isValid && !isSubmitting
                    ? () => _submit(context, ref)
                    : null,
              ),
              const SizedBox(height: KhatirSpacing.s4),
              // Submit button (loading-aware, disabled until valid).
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isValid && !isSubmitting
                      ? () => _submit(context, ref)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KhatirColors.sage,
                    foregroundColor: KhatirColors.cream,
                    disabledBackgroundColor:
                        KhatirColors.sage.withValues(alpha: 0.4),
                    disabledForegroundColor: KhatirColors.cream,
                    elevation: 0,
                    textStyle: AppTextStyles.labelLarge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(KhatirRadius.button),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              KhatirColors.cream,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.auth_phone_submit),
                            const SizedBox(width: KhatirSpacing.s2),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: KhatirSpacing.s3),
              // WhatsApp note.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KhatirSpacing.s4,
                  vertical: KhatirSpacing.s3,
                ),
                decoration: BoxDecoration(
                  color: KhatirColors.sageBg,
                  borderRadius: BorderRadius.circular(KhatirRadius.tile),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                      color: KhatirColors.sageDk,
                    ),
                    const SizedBox(width: KhatirSpacing.s3),
                    Expanded(
                      child: Text(
                        l10n.auth_phone_whatsapp,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: KhatirColors.sageDk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The labelled phone input row: `🇧🇩 +88`, a thin divider, then the local
/// number field. Validation errors render beneath it.
class _PhoneField extends ConsumerWidget {
  const _PhoneField({
    required this.enabled,
    required this.hasError,
    required this.errorText,
    required this.onSubmit,
  });

  final bool enabled;
  final bool hasError;
  final String? errorText;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(phoneFormControllerProvider);
    // Inline "invalid format" hint once the user has typed enough to judge.
    final showFormatError =
        value.isNotEmpty && localDigits(value).length >= 11 && !isValidBdPhone(value);
    final showError = hasError || showFormatError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.auth_phone_label,
          style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.muted),
        ),
        const SizedBox(height: KhatirSpacing.s2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: KhatirSpacing.s4),
          decoration: BoxDecoration(
            color: KhatirColors.card,
            borderRadius: BorderRadius.circular(KhatirRadius.md),
            border: Border.all(
              color: showError ? KhatirColors.danger : KhatirColors.line,
            ),
          ),
          child: Row(
            children: [
              Text(
                '🇧🇩 +88',
                style: AppTextStyles.titleLarge.copyWith(
                  color: KhatirColors.sageDk,
                ),
              ),
              Container(
                width: 1,
                height: 26,
                margin: const EdgeInsets.symmetric(
                  horizontal: KhatirSpacing.s3,
                ),
                color: KhatirColors.line,
              ),
              Expanded(
                child: TextField(
                  key: const Key('phone_field'),
                  enabled: enabled,
                  autofocus: false,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onChanged: (v) =>
                      ref.read(phoneFormControllerProvider.notifier).update(v),
                  onSubmitted: (_) => onSubmit?.call(),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: l10n.auth_phone_hint,
                    hintStyle: AppTextStyles.bodyLarge.copyWith(
                      color: KhatirColors.muted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: KhatirSpacing.s4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showError) ...[
          const SizedBox(height: KhatirSpacing.s2),
          Text(
            errorText ?? l10n.auth_phone_invalid,
            style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.danger),
          ),
        ],
      ],
    );
  }
}
