import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'manager_repository.dart';
import 'models/manager_models.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// The shared [ManagerRepository], backed by the app-wide dio client.
final managerRepositoryProvider = Provider<ManagerRepository>(
  (ref) => ManagerRepository(ref.watch(dioClientProvider)),
);

// ---------------------------------------------------------------------------
// Owners
// ---------------------------------------------------------------------------

/// Loads and manages the list of owners linked to this manager.
///
/// Exposed as an [AsyncNotifier] so the screen can pull-to-refresh and trigger
/// mutations (link request) without replacing the provider graph node.
final managerOwnersProvider =
    AsyncNotifierProvider<ManagerOwnersController, List<LinkedOwner>>(
  ManagerOwnersController.new,
);

/// Drives the linked-owners list, providing [refresh] and [requestOwner].
class ManagerOwnersController extends AsyncNotifier<List<LinkedOwner>> {
  @override
  Future<List<LinkedOwner>> build() => _repo.listOwners();

  ManagerRepository get _repo => ref.read(managerRepositoryProvider);

  /// Re-fetches the owners list.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.listOwners);
  }

  /// Sends an owner link request, then refreshes the list on success.
  Future<void> requestOwner({
    required String ownerPhone,
    required String ownerName,
    required List<String> permissions,
  }) async {
    await _repo.requestOwner(
      ownerPhone: ownerPhone,
      ownerName: ownerName,
      permissions: permissions,
    );
    await refresh();
  }
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

/// Loads the manager's portfolio-wide dashboard aggregates.
final managerDashboardProvider =
    AsyncNotifierProvider<ManagerDashboardController, ManagerDashboard>(
  ManagerDashboardController.new,
);

/// Drives the manager dashboard, providing [refresh].
class ManagerDashboardController extends AsyncNotifier<ManagerDashboard> {
  @override
  Future<ManagerDashboard> build() => _repo.fetchDashboard();

  ManagerRepository get _repo => ref.read(managerRepositoryProvider);

  /// Re-fetches the dashboard payload.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.fetchDashboard);
  }
}

// ---------------------------------------------------------------------------
// Team
// ---------------------------------------------------------------------------

/// Loads and manages the manager's team members.
final managerTeamProvider =
    AsyncNotifierProvider<ManagerTeamController, List<TeamMember>>(
  ManagerTeamController.new,
);

/// Drives the team list, providing [refresh], [addMember], [removeMember].
class ManagerTeamController extends AsyncNotifier<List<TeamMember>> {
  @override
  Future<List<TeamMember>> build() => _repo.listTeam();

  ManagerRepository get _repo => ref.read(managerRepositoryProvider);

  /// Re-fetches the team list.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.listTeam);
  }

  /// Adds a new team member, then refreshes the list. Returns the created
  /// [TeamMember] for immediate use (e.g. showing a confirmation banner).
  Future<TeamMember> addMember({
    required String phone,
    required String name,
    required String role,
    List<String>? scopeOwnerIds,
  }) async {
    final member = await _repo.addTeamMember(
      phone: phone,
      name: name,
      role: role,
      scopeOwnerIds: scopeOwnerIds,
    );
    await refresh();
    return member;
  }

  /// Removes a team member by ID, then refreshes the list.
  Future<void> removeMember(String memberId) async {
    await _repo.removeTeamMember(memberId);
    await refresh();
  }
}

// ---------------------------------------------------------------------------
// Owner reports (family — keyed by ownerId)
// ---------------------------------------------------------------------------

/// Loads and manages the financial report for a single linked owner.
///
/// Keyed by `ownerId` so each owner's report is independently cached and
/// refreshable.
final ownerReportProvider = AsyncNotifierProvider.family<OwnerReportController,
    OwnerReport, String>(
  OwnerReportController.new,
);

/// Drives one owner's report view, providing [generateReport].
class OwnerReportController
    extends FamilyAsyncNotifier<OwnerReport, String> {
  @override
  Future<OwnerReport> build(String ownerId) =>
      _repo.fetchOwnerReport(ownerId);

  ManagerRepository get _repo => ref.read(managerRepositoryProvider);

  /// Triggers server-side PDF generation, then updates [state] with the
  /// returned [OwnerReport] (which carries a signed [OwnerReport.pdfUrl]).
  Future<void> generateReport() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.generateOwnerReport(arg));
  }
}
