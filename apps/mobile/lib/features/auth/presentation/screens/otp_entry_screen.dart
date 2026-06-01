import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/router/args/auth_args.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home_placeholder/presentation/screens/home_placeholder_screen.dart';
import '../controllers/resend_otp_controller.dart';
import '../controllers/verify_otp_controller.dart';
import '../widgets/otp_input.dart';
import '../widgets/resend_button.dart';

/// Number of OTP digits. Spec (T-010 §2/§3) calls for a 6-box code.
const int kOtpLength = 6;

/// OTP-entry screen — mirrors the `otp` prototype (screens-onboard.js).
///
/// A back-titled top bar, a 🔐 hero with "Enter code" copy, the destination
/// phone, an N-box OTP input (auto-advance + auto-submit), a resend line with a
/// cooldown countdown and a Verify button with loading/error states. On a
/// successful verify it hands the session to the auth controller (T-011) and
/// routes onward to the authenticated home (T-012). All visual values come from
/// tokens; copy from ARB.
class OtpEntryScreen extends ConsumerStatefulWidget {
  const OtpEntryScreen({super.key, this.args});

  final AuthArgs? args;

  static const String routeName = 'auth-otp';
  static const String routePath = '/auth/otp';

  /// Destination after a successful verify. The redirect (driven by AuthState)
  /// would route here on its own once setSession flips to authenticated; this
  /// explicit nav keeps the transition immediate.
  static const String successRoutePath = HomePlaceholderScreen.routePath;

  @override
  ConsumerState<OtpEntryScreen> createState() => _OtpEntryScreenState();
}

class _OtpEntryScreenState extends ConsumerState<OtpEntryScreen> {
  final GlobalKey<OtpInputState> _inputKey = GlobalKey<OtpInputState>();
  String _code = '';

  String get _phone => widget.args?.phone ?? '';

  Future<void> _verify(String code) async {
    if (_phone.isEmpty || code.length != kOtpLength) return;
    FocusScope.of(context).unfocus();
    final result =
        await ref.read(verifyOtpControllerProvider.notifier).verify(_phone, code);
    if (!mounted) return;
    if (result == null) {
      // Error: clear the boxes so the user can retype (state holds the error).
      _inputKey.currentState?.clear();
      setState(() => _code = '');
      return;
    }
    // TODO(T-011): hand tokens+user to the auth state layer, which decides the
    // onward route (splash/role). Placeholder until then.
    context.go(OtpEntryScreen.successRoutePath);
  }

  String _errorText(AppLocalizations l10n, Object error) {
    if (error is VerifyOtpFailure) {
      return switch (error.kind) {
        VerifyOtpError.invalidCode => l10n.auth_otp_invalid,
        VerifyOtpError.expiredCode => l10n.auth_otp_expired,
        VerifyOtpError.rateLimited => l10n.auth_rate_limited,
        VerifyOtpError.network => l10n.common_network_error,
      };
    }
    return l10n.common_network_error;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final verifyState = ref.watch(verifyOtpControllerProvider);
    final resend = ref.watch(resendOtpControllerProvider);
    final isVerifying = verifyState.isLoading;

    final errorText = verifyState.maybeWhen(
      error: (e, _) => _errorText(l10n, e),
      orElse: () => null,
    );
    final hasError = errorText != null;

    final canVerify =
        _code.length == kOtpLength && !isVerifying && _phone.isNotEmpty;

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: KhatirColors.ink,
        leading: IconButton(
          key: const Key('otp_back'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.auth_otp_appbar, style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            KhatirSpacing.s6,
            KhatirSpacing.s4,
            KhatirSpacing.s6,
            KhatirSpacing.s7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔐 hero + "Enter code".
              Text(
                '🔐',
                textAlign: TextAlign.center,
                style: AppTextStyles.displayLarge.copyWith(fontSize: 48),
              ),
              const SizedBox(height: KhatirSpacing.s2),
              Text(
                l10n.auth_otp_title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: KhatirSpacing.s1),
              // "Code sent to <phone>".
              Text(
                l10n.auth_otp_sent_to(_phone),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: KhatirColors.muted,
                ),
              ),
              const SizedBox(height: KhatirSpacing.s6),
              // N-box OTP input.
              OtpInput(
                key: _inputKey,
                length: kOtpLength,
                enabled: !isVerifying,
                hasError: hasError,
                onChanged: (v) => setState(() => _code = v),
                onCompleted: _verify,
              ),
              if (hasError) ...[
                const SizedBox(height: KhatirSpacing.s3),
                Text(
                  errorText,
                  key: const Key('otp_error'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: KhatirColors.danger,
                  ),
                ),
              ],
              const SizedBox(height: KhatirSpacing.s5),
              // Resend line with cooldown countdown.
              ResendButton(
                secondsRemaining: resend.secondsRemaining,
                isSending: resend.isSending,
                localeCode: localeCode,
                onResend: () => ref
                    .read(resendOtpControllerProvider.notifier)
                    .resend(_phone),
              ),
              const SizedBox(height: KhatirSpacing.s6),
              // Verify button (loading-aware, disabled until full code).
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  key: const Key('otp_verify'),
                  onPressed: canVerify ? () => _verify(_code) : null,
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
                  child: isVerifying
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
                            Text(l10n.auth_otp_verify),
                            const SizedBox(width: KhatirSpacing.s2),
                            const Icon(Icons.check_rounded, size: 18),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
