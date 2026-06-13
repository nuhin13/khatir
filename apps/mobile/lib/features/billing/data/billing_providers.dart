import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'billing_repository.dart';
import 'models/plan_models.dart';

/// The shared [BillingRepository], backed by the app-wide dio client.
final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => BillingRepository(ref.watch(dioClientProvider)),
);

/// Loads the plan & billing slice of `/config/public` (active tiers + the
/// caller's current subscription/usage) as [AsyncValue]. Exposed as an
/// [AsyncNotifier] so the plan screen can re-read after a successful subscribe
/// to refresh usage + the current-plan highlight.
final planConfigProvider =
    AsyncNotifierProvider<PlanConfigController, PlanConfig>(
  PlanConfigController.new,
);

/// Drives the plan-config read, exposing the catalogue + subscription as
/// [AsyncValue] with a [refresh] for retry / post-subscribe reload.
class PlanConfigController extends AsyncNotifier<PlanConfig> {
  @override
  Future<PlanConfig> build() => _repo.fetchPlanConfig();

  BillingRepository get _repo => ref.read(billingRepositoryProvider);

  /// Re-fetches `/config/public` into [state].
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.fetchPlanConfig);
  }
}

/// Drives the subscribe/upgrade action (T-004). The plan screen watches this to
/// show a "subscribing" state and disable the tier cards while a request is in
/// flight; on success it refreshes [planConfigProvider]. `void` data because the
/// resulting subscription is read back via `/config/public`, not this call.
final subscribeControllerProvider =
    AsyncNotifierProvider<SubscribeController, void>(
  SubscribeController.new,
);

/// An [AsyncNotifier] whose [subscribe] posts to `/billing/subscribe` and, on
/// success, reloads the plan config so the screen reflects the new plan.
class SubscribeController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Subscribes / upgrades to [tierKey], then refreshes the plan config.
  /// Returns true on success (so the caller can show a confirmation) and false
  /// when the request failed (the error is also reflected in [state]).
  Future<bool> subscribe(String tierKey) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => ref.read(billingRepositoryProvider).subscribe(tierKey),
    );
    state = result;
    if (result.hasError) return false;
    await ref.read(planConfigProvider.notifier).refresh();
    return true;
  }
}
