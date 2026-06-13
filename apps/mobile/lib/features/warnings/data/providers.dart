import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'models/warning_enums.dart';
import 'models/models.dart';
import 'warning_repository.dart';

/// The shared [WarningRepository], backed by the app-wide dio client.
final warningRepositoryProvider = Provider<WarningRepository>(
  (ref) => WarningRepository(ref.watch(dioClientProvider)),
);

// ── Warnings list for a lease ────────────────────────────────────────────--

/// Loads the caller's warnings for one lease as [AsyncValue], with a [refresh]
/// for pull-to-retry. Keyed by lease id. Scoped server-side so it only ever
/// yields warnings the caller (landlord) owns. Used by T-008 (unit/lease
/// detail warnings section).
class LeaseWarningsController
    extends FamilyAsyncNotifier<List<Warning>, String> {
  @override
  Future<List<Warning>> build(String leaseId) =>
      _repo.listWarnings(leaseId);

  WarningRepository get _repo => ref.read(warningRepositoryProvider);

  /// Re-fetches this lease's warnings into [state].
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.listWarnings(arg));
  }
}

/// The caller's warnings for one lease, keyed by lease id.
final leaseWarningsProvider =
    AsyncNotifierProvider.family<LeaseWarningsController, List<Warning>, String>(
  LeaseWarningsController.new,
);

// ── Issue warning controller ──────────────────────────────────────────────--

/// State for the "issue warning" form: idle while ready to submit; loading
/// while the POST is in-flight; error if it failed; data (the issued [Warning])
/// on success. Keyed by lease id so the form can open for any lease.
class IssueWarningController
    extends FamilyAsyncNotifier<Warning?, String> {
  @override
  Future<Warning?> build(String leaseId) async => null;

  WarningRepository get _repo => ref.read(warningRepositoryProvider);

  /// Issues a warning for the current lease, then appends the new warning to
  /// the cached list so the lease-detail section updates without a full
  /// re-fetch.
  Future<Warning> issue({
    required WarningType warningType,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    final warning = await _repo.issueWarning(
      leaseId: arg,
      warningType: warningType,
      reason: reason,
    );
    state = AsyncValue.data(warning);
    // Invalidate the list so detail screens pick up the newly issued warning.
    ref.invalidate(leaseWarningsProvider(arg));
    return warning;
  }
}

/// Issue-warning form state, keyed by lease id.
final issueWarningProvider =
    AsyncNotifierProvider.family<IssueWarningController, Warning?, String>(
  IssueWarningController.new,
);

// ── Notice PDF controller ─────────────────────────────────────────────────--

/// The downloaded warning notice PDF bytes + the originating [WarningNotice]
/// metadata (notice ref + warning id used for a stable share filename).
class WarningNoticePdf {
  const WarningNoticePdf({required this.bytes, required this.notice});

  final Uint8List bytes;
  final WarningNotice notice;
}

/// Generates the warning notice PDF for one warning then downloads its bytes,
/// exposing [AsyncValue] (loading=generating / error / data=ready-to-preview).
/// Keyed by warning id via [family]. [regenerate] re-runs the pipeline for
/// the error-state retry button.
class WarningNoticePdfController
    extends FamilyAsyncNotifier<WarningNoticePdf, String> {
  @override
  Future<WarningNoticePdf> build(String warningId) => _generate(warningId);

  WarningRepository get _repo => ref.read(warningRepositoryProvider);

  Future<WarningNoticePdf> _generate(String warningId) async {
    final notice = await _repo.generateNotice(warningId);
    final bytes = await _repo.fetchNoticePdfBytes(notice.signedUrl);
    return WarningNoticePdf(bytes: bytes, notice: notice);
  }

  /// Re-runs generate → download into [state] (error-state retry).
  Future<void> regenerate() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _generate(arg));
  }
}

/// Warning notice PDF generation state, keyed by warning id.
final warningNoticePdfProvider =
    AsyncNotifierProvider.family<WarningNoticePdfController, WarningNoticePdf,
        String>(
  WarningNoticePdfController.new,
);
