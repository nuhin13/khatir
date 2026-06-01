import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/auth_providers.dart';
import '../../data/models/verify_otp_response.dart';

/// Distinguishes the verify failures the OTP screen renders friendly copy for.
enum VerifyOtpError { invalidCode, expiredCode, rateLimited, network }

/// Thrown by [VerifyOtpController] so the screen maps a failure to a localised
/// message without inspecting raw [ApiException]s.
class VerifyOtpFailure implements Exception {
  const VerifyOtpFailure(this.kind);
  final VerifyOtpError kind;
}

/// Drives the `verify-otp` action for the OTP-entry screen.
///
/// State is `AsyncValue<void>`: `data(null)` = idle/success, `loading` while a
/// request is in flight, `error` carries a [VerifyOtpFailure]. The verified
/// [VerifyOtpResponse] is returned from [verify] (not stored in state) so the
/// screen can hand the tokens+user onward.
class VerifyOtpController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Idle until the user submits a full code.
  }

  /// Verifies [code] for [phone] (E.164-normalised).
  ///
  /// Returns the [VerifyOtpResponse] on success (tokens + user) for the screen
  /// to route onward, or `null` if the request failed — in which case [state]
  /// holds a [VerifyOtpFailure].
  Future<VerifyOtpResponse?> verify(String phone, String code) async {
    state = const AsyncValue.loading();
    VerifyOtpResponse? verified;
    final result = await AsyncValue.guard(() async {
      try {
        verified = await ref.read(authRepositoryProvider).verifyOtp(
              phone,
              code,
            );
      } on ApiException catch (e) {
        throw VerifyOtpFailure(_mapStatus(e.statusCode));
      }
    });
    state = result;
    if (result.hasError || verified == null) return null;

    // Hand the issued session to the auth-state controller (T-011): it persists
    // the token pair to secure storage and flips auth state to authenticated,
    // seeding the user from the verify payload when present.
    final tokens = verified!;
    final user = tokens.user;
    await ref.read(authControllerProvider.notifier).setSession(
          access: tokens.access,
          refresh: tokens.refresh,
          user: user == null
              ? null
              : SessionUser(
                  id: user.id ?? '',
                  phone: user.phone,
                ),
        );
    return tokens;
  }

  /// Resets the controller to idle (e.g. when the user edits the code after an
  /// error, so the inline error clears).
  void reset() => state = const AsyncValue.data(null);

  VerifyOtpError _mapStatus(int? status) {
    return switch (status) {
      401 || 422 || 400 => VerifyOtpError.invalidCode,
      410 => VerifyOtpError.expiredCode,
      429 => VerifyOtpError.rateLimited,
      _ => VerifyOtpError.network,
    };
  }
}

final verifyOtpControllerProvider =
    AutoDisposeAsyncNotifierProvider<VerifyOtpController, void>(
  VerifyOtpController.new,
);
