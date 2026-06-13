import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'models/verification_result.dart';
import 'verification_repository.dart';

/// The shared [VerificationRepository], backed by the app-wide dio client.
final verificationRepositoryProvider = Provider<VerificationRepository>(
  (ref) => VerificationRepository(ref.watch(dioClientProvider)),
);

// ── Verification state machine ───────────────────────────────────────────────

/// Possible states of the verify-screen action.
sealed class VerifyState {
  const VerifyState();
}

/// No verification in flight yet (initial / consent not checked).
class VerifyIdle extends VerifyState {
  const VerifyIdle();
}

/// EC verify call in progress.
class VerifyLoading extends VerifyState {
  const VerifyLoading();
}

/// Verification completed (matched, not_matched, or error from server).
class VerifyDone extends VerifyState {
  const VerifyDone(this.result);
  final VerificationResult result;
}

/// Local/network failure (couldn't reach the server).
class VerifyFailure extends VerifyState {
  const VerifyFailure(this.message);
  final String message;
}

// ── VerifyController ─────────────────────────────────────────────────────────

/// Drives the NID verify screen action for one tenant.
///
/// [build] starts [VerifyIdle] and optionally pre-loads any existing result.
/// [run] posts the verify request and transitions through loading → done/fail.
class VerifyController extends FamilyAsyncNotifier<VerifyState, String> {
  @override
  Future<VerifyState> build(String tenantId) async {
    // Pre-load any existing verification so the screen can show the current
    // state (e.g. already verified) before the user acts.
    final existing = await ref
        .read(verificationRepositoryProvider)
        .getVerification(tenantId);
    if (existing != null) return VerifyDone(existing);
    return const VerifyIdle();
  }

  VerificationRepository get _repo => ref.read(verificationRepositoryProvider);

  /// Resets the state back to [VerifyIdle] so the user can re-check consent
  /// and run again (e.g. after an error or a not-matched result).
  void resetToIdle() {
    state = const AsyncValue.data(VerifyIdle());
  }

  /// Triggers the EC verify call for [arg] (tenantId) with landlord consent.
  ///
  /// Transitions: loading → done (server returned matched/not_matched/error) or
  /// failure (couldn't reach the server). Consent must be `true` before calling.
  Future<void> run({required bool consent}) async {
    state = const AsyncValue.data(VerifyLoading());
    try {
      final result = await _repo.verify(arg, consent: consent);
      state = AsyncValue.data(VerifyDone(result));
    } catch (e) {
      state = AsyncValue.data(VerifyFailure(e.toString()));
    }
  }
}

/// Keyed by tenant id. Use [verifyControllerProvider('tenantId')] in screens.
final verifyControllerProvider = AsyncNotifierProvider.family<
    VerifyController,
    VerifyState,
    String>(
  VerifyController.new,
);
