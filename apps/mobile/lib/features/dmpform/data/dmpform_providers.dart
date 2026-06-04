import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'dmpform_repository.dart';
import 'models/dmp_preview.dart';

/// The shared [DmpFormRepository], backed by the app-wide dio client.
final dmpFormRepositoryProvider = Provider<DmpFormRepository>(
  (ref) => DmpFormRepository(ref.watch(dioClientProvider)),
);

/// Loads the assembled DMP-form preview for one tenant, exposing [AsyncValue]
/// (loading / error / data). Keyed by tenant id via [family] so the preview
/// screen can be opened for any tenant. [refresh] re-fetches into [state] for
/// the error-state retry button.
class DmpPreviewController extends FamilyAsyncNotifier<DmpPreview, String> {
  @override
  Future<DmpPreview> build(String tenantId) => _repo.getPreview(tenantId);

  DmpFormRepository get _repo => ref.read(dmpFormRepositoryProvider);

  /// Re-fetches this tenant's DMP preview into [state].
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getPreview(arg));
  }
}

/// DMP-form preview state, keyed by tenant id.
final dmpPreviewProvider =
    AsyncNotifierProvider.family<DmpPreviewController, DmpPreview, String>(
  DmpPreviewController.new,
);
