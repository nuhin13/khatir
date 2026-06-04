import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'lease_repository.dart';
import 'models/lease_enums.dart';
import 'models/models.dart';

/// The shared [LeaseRepository], backed by the app-wide dio client.
final leaseRepositoryProvider = Provider<LeaseRepository>(
  (ref) => LeaseRepository(ref.watch(dioClientProvider)),
);

// ── A single lease's rent schedule ────────────────────────────────────────--

/// Loads a lease's rent schedule, keyed by lease id, exposing [AsyncValue].
/// Used by the lease detail screen (T-010) to show the period rows.
final leaseScheduleProvider =
    FutureProvider.family<List<RentSchedule>, String>(
  (ref, leaseId) => ref.watch(leaseRepositoryProvider).getSchedule(leaseId),
);

// ── A unit's current (active) lease ───────────────────────────────────────--

/// Loads a unit's current (active) lease + embedded tenant summary, keyed by
/// unit id. Errors (incl. the 404 when a unit has no active lease) surface via
/// [AsyncValue.error]; the unit-detail screen (T-009) treats a 404 as "no
/// active lease".
final unitLeaseProvider = FutureProvider.family<UnitLease, String>(
  (ref, unitId) => ref.watch(leaseRepositoryProvider).getUnitLease(unitId),
);

// ── Lease lifecycle controller ────────────────────────────────────────────--

/// Drives one lease's lifecycle (create-then-track / activate / terminate /
/// edit), exposing the current [Lease] as [AsyncValue]. Keyed by lease id;
/// [build] fetches `GET /leases/{id}`.
///
/// The create flow lives on [createDraft] (a static-style helper on the repo
/// via the provider) rather than here because a new draft has no id yet — see
/// [LeaseController.activate]/[terminate]/[update] for the transitions that
/// operate on an existing, addressable lease.
class LeaseController extends FamilyAsyncNotifier<Lease, String> {
  @override
  Future<Lease> build(String leaseId) => _repo.getLease(leaseId);

  LeaseRepository get _repo => ref.read(leaseRepositoryProvider);

  /// Re-fetches this lease into [state].
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getLease(arg));
  }

  /// Activates this draft lease (server generates the schedule), then writes
  /// the activated lease into [state] and invalidates its schedule so the
  /// freshly generated rows are re-fetched.
  Future<Lease> activate() async {
    final lease = await _repo.activateLease(arg);
    state = AsyncValue.data(lease);
    ref.invalidate(leaseScheduleProvider(arg));
    return lease;
  }

  /// Terminates/ends this active lease, then writes the closed lease into
  /// [state]. [status] chooses ended vs. terminated (default terminated).
  Future<Lease> terminate({LeaseStatus? status}) async {
    final lease = await _repo.terminateLease(arg, status: status);
    state = AsyncValue.data(lease);
    return lease;
  }

  /// Partial-updates this draft lease's terms/dates, then writes the updated
  /// lease into [state]. Only non-null fields are sent. (Named [editTerms] to
  /// avoid clashing with the inherited `AsyncNotifier.update`.)
  Future<Lease> editTerms({
    DateTime? startDate,
    DateTime? endDate,
    double? rent,
    double? advance,
    String? signedPdfRef,
  }) async {
    final lease = await _repo.updateLease(
      arg,
      startDate: startDate,
      endDate: endDate,
      rent: rent,
      advance: advance,
      signedPdfRef: signedPdfRef,
    );
    state = AsyncValue.data(lease);
    return lease;
  }
}

/// One lease's lifecycle state, keyed by lease id.
final leaseControllerProvider =
    AsyncNotifierProvider.family<LeaseController, Lease, String>(
  LeaseController.new,
);
