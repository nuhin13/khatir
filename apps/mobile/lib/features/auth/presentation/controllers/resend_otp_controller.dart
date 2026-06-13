import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/auth_providers.dart';

/// Default resend cooldown (seconds). Mirrors the backend
/// `otp_resend_cooldown_seconds`; the server value (when surfaced via
/// `retry_after_seconds`) overrides this on a successful resend.
const int kOtpResendCooldownSeconds = 60;

/// State of the resend action: seconds remaining on the cooldown, whether a
/// resend request is currently in flight, and whether the last resend failed.
class ResendOtpState {
  const ResendOtpState({
    this.secondsRemaining = 0,
    this.isSending = false,
    this.failed = false,
  });

  /// Seconds left before the user may resend again. `0` = resend allowed.
  final int secondsRemaining;

  /// True while a resend request is in flight.
  final bool isSending;

  /// True if the last resend attempt failed (so the screen can hint a retry).
  final bool failed;

  /// Resend is permitted only when not counting down and not already sending.
  bool get canResend => secondsRemaining == 0 && !isSending;

  ResendOtpState copyWith({
    int? secondsRemaining,
    bool? isSending,
    bool? failed,
  }) {
    return ResendOtpState(
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isSending: isSending ?? this.isSending,
      failed: failed ?? this.failed,
    );
  }
}

/// Owns the resend button's cooldown countdown and the resend request itself.
///
/// Starts a cooldown immediately on build (the code was just sent by the
/// phone-entry step). A successful resend restarts the countdown.
class ResendOtpController extends AutoDisposeNotifier<ResendOtpState> {
  Timer? _timer;

  @override
  ResendOtpState build() {
    ref.onDispose(() => _timer?.cancel());
    // A code was already sent before reaching this screen → start cooling down.
    // The ticking timer is started after build completes (can't mutate `state`
    // synchronously during build).
    _scheduleTimer(kOtpResendCooldownSeconds);
    return const ResendOtpState(secondsRemaining: kOtpResendCooldownSeconds);
  }

  void _scheduleTimer(int seconds) {
    _timer?.cancel();
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.secondsRemaining - 1;
      if (next <= 0) {
        timer.cancel();
        state = state.copyWith(secondsRemaining: 0);
      } else {
        state = state.copyWith(secondsRemaining: next);
      }
    });
  }

  /// Resets the countdown to [seconds] and (re)starts the ticking timer. Safe
  /// to call after build completes.
  void _restartCountdown(int seconds) {
    state = state.copyWith(secondsRemaining: seconds);
    _scheduleTimer(seconds);
  }

  /// Re-requests an OTP for [phone] (E.164-normalised) and restarts the
  /// cooldown. No-op while counting down or already sending.
  Future<void> resend(String phone) async {
    if (!state.canResend) return;
    state = state.copyWith(isSending: true, failed: false);
    try {
      final res = await ref.read(authRepositoryProvider).resendOtp(phone);
      final cooldown = res.retryAfterSeconds ?? kOtpResendCooldownSeconds;
      state = state.copyWith(isSending: false);
      _restartCountdown(cooldown);
    } on ApiException catch (e) {
      final cooldown = e.statusCode == 429 ? kOtpResendCooldownSeconds : 0;
      state = state.copyWith(isSending: false, failed: true);
      if (cooldown > 0) _restartCountdown(cooldown);
    }
  }
}

final resendOtpControllerProvider =
    AutoDisposeNotifierProvider<ResendOtpController, ResendOtpState>(
  ResendOtpController.new,
);
