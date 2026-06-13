import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'models/models.dart';
import 'models/tenant_enums.dart';
import 'tenant_repository.dart';

// ── Repository ─────────────────────────────────────────────────────────────

/// The shared [TenantRepository], backed by the app-wide Dio client.
final tenantRepositoryProvider = Provider<TenantRepository>(
  (ref) => TenantRepository(ref.watch(dioClientProvider)),
);

// ── Lease ──────────────────────────────────────────────────────────────────

/// The authenticated tenant's active lease, exposed as [AsyncValue]. Returns
/// null when the tenant has no active lease. Scoped server-side via JWT.
final myLeaseProvider = FutureProvider<TenantLease?>((ref) {
  return ref.watch(tenantRepositoryProvider).myLease();
});

// ── Rent ───────────────────────────────────────────────────────────────────

/// The authenticated tenant's current-month rent status, exposed as
/// [AsyncValue]. Returns null when there is no active rent record.
final myRentProvider = FutureProvider<TenantRent?>((ref) {
  return ref.watch(tenantRepositoryProvider).myRent();
});

/// Drives the payment proof submission for a rent period. Keyed by the rent
/// period id. [build] returns the current rent state; [submitProof] posts the
/// proof to the server.
class MyRentController extends FamilyAsyncNotifier<TenantRent?, String> {
  @override
  Future<TenantRent?> build(String rentId) =>
      ref.watch(tenantRepositoryProvider).myRent();

  TenantRepository get _repo => ref.read(tenantRepositoryProvider);

  /// Submits proof of payment for this rent period and writes the updated rent
  /// state into [state].
  Future<void> submitProof({
    required PayProofType proofType,
    String? value,
    String? photoRef,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.submitProof(
        rentId: arg,
        proofType: proofType,
        value: value,
        photoRef: photoRef,
      ),
    );
    // Invalidate the list provider so the home screen re-reads the status.
    ref.invalidate(myRentProvider);
  }
}

/// One rent period's payment controller, keyed by rent period id.
final myRentControllerProvider =
    AsyncNotifierProvider.family<MyRentController, TenantRent?, String>(
  MyRentController.new,
);

// ── Receipts ───────────────────────────────────────────────────────────────

/// The authenticated tenant's receipt list, exposed as [AsyncValue]. Scoped
/// server-side via JWT so it always returns only the caller's receipts.
final myReceiptsProvider = FutureProvider<List<TenantReceipt>>((ref) {
  return ref.watch(tenantRepositoryProvider).myReceipts();
});

// ── Record / rating ────────────────────────────────────────────────────────

/// The authenticated tenant's private good-tenant record, exposed as
/// [AsyncValue]. Returns null when no record exists yet.
final myRecordProvider = FutureProvider<TenantRecord?>((ref) {
  return ref.watch(tenantRepositoryProvider).myRecord();
});

/// Drives the tenant's private record / rating CRUD. [build] loads the current
/// record; [save] creates or updates it.
class MyRecordController extends AsyncNotifier<TenantRecord?> {
  @override
  Future<TenantRecord?> build() =>
      ref.watch(tenantRepositoryProvider).myRecord();

  TenantRepository get _repo => ref.read(tenantRepositoryProvider);

  /// Creates or updates the tenant record. Sends only the non-null fields.
  Future<void> save({
    required int rating,
    required String notes,
    required RecordConsent consent,
  }) async {
    state = const AsyncValue.loading();
    // Try to update first; if no record exists (null), create one.
    final existing = state.valueOrNull;
    if (existing == null) {
      state = await AsyncValue.guard(
        () => _repo.createRecord(
          rating: rating,
          notes: notes,
          consent: consent,
        ),
      );
    } else {
      state = await AsyncValue.guard(
        () => _repo.updateRecord(
          rating: rating,
          notes: notes,
          consent: consent,
        ),
      );
    }
    ref.invalidate(myRecordProvider);
  }
}

/// The tenant's private record / rating controller.
final myRecordControllerProvider =
    AsyncNotifierProvider<MyRecordController, TenantRecord?>(
  MyRecordController.new,
);

// ── Maintenance reports ────────────────────────────────────────────────────

/// The authenticated tenant's maintenance reports list, exposed as [AsyncValue].
final myMaintenanceReportsProvider =
    FutureProvider<List<TenantMaintenanceReport>>((ref) {
  return ref.watch(tenantRepositoryProvider).myMaintenanceReports();
});

/// Drives maintenance report submission. [submit] posts the report and
/// invalidates the list so the screen refreshes.
class MyMaintenanceController
    extends AsyncNotifier<List<TenantMaintenanceReport>> {
  @override
  Future<List<TenantMaintenanceReport>> build() =>
      ref.watch(tenantRepositoryProvider).myMaintenanceReports();

  TenantRepository get _repo => ref.read(tenantRepositoryProvider);

  /// Posts a new maintenance report to the landlord queue. The submitted
  /// report is appended to [state] optimistically and the list is invalidated
  /// for a server re-fetch.
  Future<void> submit({
    required String description,
    TenantMaintenanceCategory category = TenantMaintenanceCategory.other,
    String? photoRef,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.reportMaintenance(
        description: description,
        category: category,
        photoRef: photoRef,
      );
      return _repo.myMaintenanceReports();
    });
    ref.invalidate(myMaintenanceReportsProvider);
  }
}

/// The tenant's maintenance reports controller.
final myMaintenanceControllerProvider = AsyncNotifierProvider<
    MyMaintenanceController, List<TenantMaintenanceReport>>(
  MyMaintenanceController.new,
);
