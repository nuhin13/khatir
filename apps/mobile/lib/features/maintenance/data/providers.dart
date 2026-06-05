import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'expense_repository.dart';
import 'maintenance_repository.dart';
import 'models/maintenance_enums.dart';
import 'models/models.dart';

/// The shared [MaintenanceRepository], backed by the app-wide dio client.
final maintenanceRepositoryProvider = Provider<MaintenanceRepository>(
  (ref) => MaintenanceRepository(ref.watch(dioClientProvider)),
);

/// The shared [ExpenseRepository], backed by the app-wide dio client.
final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(ref.watch(dioClientProvider)),
);

// ── The maintenance queue ─────────────────────────────────────────────────--

/// Loads the caller's maintenance queue (one page) as [AsyncValue], keyed by an
/// optional [MaintenanceStatus] tab filter (null = all). Scoped server-side via
/// `for_user`, so it only ever yields requests the user owns. Used by the
/// maintenance-queue screen (T-010); the `null` family entry is the default
/// "all" tab.
final maintenanceQueueProvider = AsyncNotifierProvider.family<
    MaintenanceQueueController, List<MaintenanceRequest>, MaintenanceStatus?>(
  MaintenanceQueueController.new,
);

/// Drives one queue tab (a [MaintenanceStatus] filter, or null for all),
/// exposing the request list as [AsyncValue] with a [refresh] for pull-to-retry.
class MaintenanceQueueController
    extends FamilyAsyncNotifier<List<MaintenanceRequest>, MaintenanceStatus?> {
  @override
  Future<List<MaintenanceRequest>> build(MaintenanceStatus? status) =>
      _repo.listQueue(status: status);

  MaintenanceRepository get _repo => ref.read(maintenanceRepositoryProvider);

  /// Re-fetches this tab's queue into [state].
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.listQueue(status: arg));
  }
}

// ── A single maintenance request ──────────────────────────────────────────--

/// Loads one maintenance request, keyed by id, exposing [AsyncValue].
/// Foreign/unknown ids surface as [AsyncValue.error] (the server resolves them to
/// 404). Used by the request-detail screen (T-011).
final maintenanceRequestProvider =
    FutureProvider.family<MaintenanceRequest, String>(
  (ref, id) => ref.watch(maintenanceRepositoryProvider).getRequest(id),
);

// ── One request's lifecycle controller ────────────────────────────────────--

/// Drives one maintenance request's lifecycle (update / resolve), exposing the
/// current [MaintenanceRequest] as [AsyncValue]. Keyed by request id; [build]
/// fetches `GET /maintenance/{id}`.
///
/// The create flow lives on the repository (a new request has no id yet) — see
/// [MaintenanceRepository.createRequest]. After a transition the updated request
/// is written into [state] and the single-request provider is invalidated so a
/// detail screen re-reads the fresh row.
class MaintenanceRequestController
    extends FamilyAsyncNotifier<MaintenanceRequest, String> {
  @override
  Future<MaintenanceRequest> build(String requestId) =>
      _repo.getRequest(requestId);

  MaintenanceRepository get _repo => ref.read(maintenanceRepositoryProvider);

  /// Re-fetches this request into [state].
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getRequest(arg));
  }

  /// Partial-updates this request's descriptive fields, then writes the updated
  /// request into [state]. Named `updateRequest` (not `update`) so it does not
  /// collide with [AsyncNotifier.update].
  Future<MaintenanceRequest> updateRequest({
    String? description,
    MaintenanceCategory? category,
    String? photoRef,
  }) =>
      _transition(
        () => _repo.updateRequest(
          arg,
          description: description,
          category: category,
          photoRef: photoRef,
        ),
      );

  /// Resolves this request with [cost] (auto-creates one expense server-side)
  /// plus an optional [note], then writes the resolved request into [state].
  Future<MaintenanceRequest> resolve({required double cost, String? note}) =>
      _transition(() => _repo.resolve(arg, cost: cost, note: note));

  /// Shared transition runner: awaits [action], writes the returned request into
  /// [state], and invalidates the single-request provider so detail re-reads.
  Future<MaintenanceRequest> _transition(
    Future<MaintenanceRequest> Function() action,
  ) async {
    final request = await action();
    state = AsyncValue.data(request);
    ref.invalidate(maintenanceRequestProvider(arg));
    return request;
  }
}

/// One maintenance request's lifecycle state, keyed by request id.
final maintenanceRequestControllerProvider = AsyncNotifierProvider.family<
    MaintenanceRequestController, MaintenanceRequest, String>(
  MaintenanceRequestController.new,
);

// ── The expense list ──────────────────────────────────────────────────────--

/// Loads the caller's expenses (one page) as [AsyncValue], keyed by an optional
/// [ExpenseFilter] (null = all). Scoped server-side via `for_user`. Used by the
/// expenses-list screen (T-008). Both manual and auto expenses appear.
final expenseListProvider =
    AsyncNotifierProvider.family<ExpenseListController, List<Expense>,
        ExpenseFilter?>(
  ExpenseListController.new,
);

/// Drives the (optionally filtered) expense list, exposing it as [AsyncValue]
/// with a [refresh] for pull-to-retry and a [delete] helper that removes an
/// expense and re-fetches.
class ExpenseListController
    extends FamilyAsyncNotifier<List<Expense>, ExpenseFilter?> {
  @override
  Future<List<Expense>> build(ExpenseFilter? filter) =>
      _repo.listExpenses(filter: filter);

  ExpenseRepository get _repo => ref.read(expenseRepositoryProvider);

  /// Re-fetches this filter's expenses into [state].
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.listExpenses(filter: arg));
  }

  /// Deletes the expense [id] then re-fetches the list into [state].
  Future<void> delete(String id) async {
    await _repo.deleteExpense(id);
    await refresh();
  }
}

// ── A single expense ──────────────────────────────────────────────────────--

/// Loads one expense, keyed by id, exposing [AsyncValue]. Foreign/unknown ids
/// surface as [AsyncValue.error] (the server resolves them to 404). Used by the
/// expense-detail / edit screen (T-009).
final expenseProvider = FutureProvider.family<Expense, String>(
  (ref, id) => ref.watch(expenseRepositoryProvider).getExpense(id),
);

// ── The expense summary (dashboard) ───────────────────────────────────────--

/// Loads the per-category / per-month expense summary as [AsyncValue], keyed by
/// an optional [ExpenseFilter] (null = all). Used by the expense-summary hook on
/// the dashboard (T-012).
final expenseSummaryProvider =
    FutureProvider.family<ExpenseSummary, ExpenseFilter?>(
  (ref, filter) => ref.watch(expenseRepositoryProvider).summary(filter: filter),
);
