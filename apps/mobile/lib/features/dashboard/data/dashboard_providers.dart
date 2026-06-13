import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'dashboard_model.dart';
import 'dashboard_repository.dart';

/// The shared [DashboardRepository], backed by the app-wide dio client.
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dioClientProvider)),
);

/// Loads the caller's dashboard payload as [AsyncValue], keyed by an optional
/// [months] window (null = the server's configured default). Scoped + cached
/// server-side, so it only ever yields the user's own numbers. Used by the
/// dashboard screen (T-006) and its cards/charts (T-008/T-009).
///
/// Exposed as an [AsyncNotifier] family so the screen can pull-to-refresh
/// (which bypasses the server's short cache by re-issuing the read) without
/// rebuilding the provider graph.
final dashboardProvider =
    AsyncNotifierProvider.family<DashboardController, DashboardData, int?>(
  DashboardController.new,
);

/// Drives one dashboard view (a [months] window, or null for the default),
/// exposing the metrics as [AsyncValue] with a [refresh] for pull-to-retry.
class DashboardController extends FamilyAsyncNotifier<DashboardData, int?> {
  @override
  Future<DashboardData> build(int? months) =>
      _repo.fetchDashboard(months: months);

  DashboardRepository get _repo => ref.read(dashboardRepositoryProvider);

  /// Re-fetches this window's dashboard into [state].
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.fetchDashboard(months: arg));
  }
}
