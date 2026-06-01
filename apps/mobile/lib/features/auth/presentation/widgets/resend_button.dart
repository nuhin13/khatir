import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/i18n/bangla_numerals.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// "Didn't get the code? Resend (0:24)" line from the `otp` prototype.
///
/// While the cooldown is active the resend label is muted and shows the
/// countdown; once it reaches zero the label becomes a tappable sage link.
class ResendButton extends StatelessWidget {
  const ResendButton({
    super.key,
    required this.secondsRemaining,
    required this.isSending,
    required this.onResend,
    required this.localeCode,
  });

  /// Seconds left on the cooldown; `0` means resend is allowed.
  final int secondsRemaining;

  /// True while a resend request is in flight.
  final bool isSending;

  /// Invoked when the user taps resend (only wired when allowed).
  final VoidCallback onResend;

  /// Active locale code ('bn' | 'en') for numeral rendering.
  final String localeCode;

  String _formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    final raw = '$m:$s';
    return localeCode == 'bn' ? BanglaNumerals.toBangla(raw) : raw;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canResend = secondsRemaining == 0 && !isSending;

    final Widget action;
    if (isSending) {
      action = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(KhatirColors.sageDk),
        ),
      );
    } else if (canResend) {
      action = GestureDetector(
        key: const Key('resend_action'),
        onTap: onResend,
        child: Text(
          l10n.auth_otp_resend,
          style: AppTextStyles.labelLarge.copyWith(color: KhatirColors.sageDk),
        ),
      );
    } else {
      action = Text(
        l10n.auth_otp_resend_in(_formatCountdown(secondsRemaining)),
        key: const Key('resend_countdown'),
        style: AppTextStyles.labelLarge.copyWith(color: KhatirColors.sageDk),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.auth_otp_no_code,
          style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.muted),
        ),
        const SizedBox(width: KhatirSpacing.s1),
        action,
      ],
    );
  }
}
