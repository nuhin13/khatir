import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/auth_providers.dart';
import '../../data/auth_repository.dart';

/// Distinguishes the failure kinds the phone-entry screen renders friendly
/// copy for (invalid input / rate-limited / network).
enum RequestOtpError { rateLimited, network }

/// Thrown by [RequestOtpController] so the screen can map a failure to a
/// localised message without inspecting raw [ApiException]s.
class RequestOtpFailure implements Exception {
  const RequestOtpFailure(this.kind);
  final RequestOtpError kind;
}

/// Drives the `request-otp` action for the phone-entry screen.
///
/// State is `AsyncValue<void>`: `data(null)` = idle/success, `loading` while
/// the request is in flight, `error` carries a [RequestOtpFailure].
class RequestOtpController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Idle until the user submits.
  }

  /// Sends the OTP request for the given local/normalised [phone].
  ///
  /// Returns the E.164-normalised phone on success (for navigation), or
  /// `null` if the request failed — in which case [state] holds the error.
  Future<String?> requestOtp(String phone) async {
    final normalised = normaliseBdPhone(phone);
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      try {
        await ref.read(authRepositoryProvider).requestOtp(normalised);
      } on ApiException catch (e) {
        if (e.statusCode == 429) {
          throw const RequestOtpFailure(RequestOtpError.rateLimited);
        }
        throw const RequestOtpFailure(RequestOtpError.network);
      }
    });
    state = result;
    return result.hasError ? null : normalised;
  }
}

final requestOtpControllerProvider =
    AutoDisposeAsyncNotifierProvider<RequestOtpController, void>(
  RequestOtpController.new,
);
