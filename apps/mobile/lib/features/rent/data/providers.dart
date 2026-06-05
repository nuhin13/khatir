import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'models/models.dart';
import 'models/rent_enums.dart';
import 'rent_repository.dart';

/// The shared [RentRepository], backed by the app-wide dio client.
final rentRepositoryProvider = Provider<RentRepository>(
  (ref) => RentRepository(ref.watch(dioClientProvider)),
);

// ── The landlord's rent-request queue ─────────────────────────────────────--

/// Loads the caller's rent-request queue (one page) as [AsyncValue], keyed by an
/// optional [RentRequestStatus] tab filter (null = all). Scoped server-side via
/// `for_user`, so it only ever yields requests the user owns. Used by the
/// rent-queue screen (T-011); the `null` family entry is the default "all" tab.
final rentQueueProvider =
    AsyncNotifierProvider.family<RentQueueController, List<RentRequest>,
        RentRequestStatus?>(
  RentQueueController.new,
);

/// Drives one queue tab (a [RentRequestStatus] filter, or null for all),
/// exposing the request list as [AsyncValue] with a [refresh] for pull-to-retry
/// and lifecycle helpers that re-fetch the tab after a transition settles.
class RentQueueController
    extends FamilyAsyncNotifier<List<RentRequest>, RentRequestStatus?> {
  @override
  Future<List<RentRequest>> build(RentRequestStatus? status) =>
      _repo.listQueue(status: status);

  RentRepository get _repo => ref.read(rentRepositoryProvider);

  /// Re-fetches this tab's queue into [state].
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.listQueue(status: arg));
  }
}

// ── A single rent request ─────────────────────────────────────────────────--

/// Loads one rent request, keyed by id, exposing [AsyncValue]. Foreign/unknown
/// ids surface as [AsyncValue.error] (the server resolves them to 404). Used by
/// the request-detail screen (T-012).
final rentRequestProvider = FutureProvider.family<RentRequest, String>(
  (ref, id) => ref.watch(rentRepositoryProvider).getRequest(id),
);

// ── One request's lifecycle controller ────────────────────────────────────--

/// Drives one rent request's lifecycle (send / verify / reject / mark-received),
/// exposing the current [RentRequest] as [AsyncValue]. Keyed by request id;
/// [build] fetches `GET /rent-requests/{id}`.
///
/// The create flow lives on the repository (a new request has no id yet) — see
/// [RentRepository.createFromSchedule]/[createManual]. After any transition the
/// settled request is written into [state] and the single-request provider is
/// invalidated so a detail screen re-reads the fresh row.
class RentRequestController extends FamilyAsyncNotifier<RentRequest, String> {
  @override
  Future<RentRequest> build(String requestId) => _repo.getRequest(requestId);

  RentRepository get _repo => ref.read(rentRepositoryProvider);

  /// Re-fetches this request into [state].
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getRequest(arg));
  }

  /// (Re)delivers the tenant link, then writes the stamped request into [state].
  Future<RentRequest> send() => _transition(() => _repo.sendRequest(arg));

  /// Verifies the submitted proof (server creates a Payment + receipt and
  /// settles), then writes the settled request into [state].
  Future<RentRequest> verify() => _transition(() => _repo.verify(arg));

  /// Records an off-platform (cash) payment with no proof and settles, then
  /// writes the settled request into [state].
  Future<RentRequest> markReceived() =>
      _transition(() => _repo.markReceived(arg));

  /// Rejects this request with a required, non-empty [reason] (no Payment is
  /// created), then writes the rejected request into [state].
  Future<RentRequest> reject({required String reason}) =>
      _transition(() => _repo.reject(arg, reason: reason));

  /// Shared transition runner: awaits [action], writes the returned request into
  /// [state], and invalidates the single-request provider so detail re-reads.
  Future<RentRequest> _transition(
    Future<RentRequest> Function() action,
  ) async {
    final request = await action();
    state = AsyncValue.data(request);
    ref.invalidate(rentRequestProvider(arg));
    return request;
  }
}

/// One rent request's lifecycle state, keyed by request id.
final rentRequestControllerProvider =
    AsyncNotifierProvider.family<RentRequestController, RentRequest, String>(
  RentRequestController.new,
);
