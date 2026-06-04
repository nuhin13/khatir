import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'dmpform_repository.dart';
import 'models/dmp_data.dart';
import 'models/dmp_pdf_result.dart';
import 'models/dmp_preview.dart';
import 'models/dmp_record.dart';

/// The shared [DmpFormRepository], backed by the app-wide dio client.
final dmpFormRepositoryProvider = Provider<DmpFormRepository>(
  (ref) => DmpFormRepository(ref.watch(dioClientProvider)),
);

/// The assembled, typed DMP data for one tenant ([DmpData], masked NID),
/// exposed as an [AsyncValue] keyed by tenant id (EPIC-05 T-009). This is the
/// canonical typed read; the preview screen uses [dmpPreviewProvider].
final dmpDataProvider =
    FutureProvider.family<DmpData, String>((ref, tenantId) {
  return ref.watch(dmpFormRepositoryProvider).getDmpData(tenantId);
});

/// A previously generated DMP record ([DmpRecord] — metadata + signed URL),
/// exposed as an [AsyncValue] keyed by record id (EPIC-05 T-009).
final dmpRecordProvider =
    FutureProvider.family<DmpRecord, String>((ref, recordId) {
  return ref.watch(dmpFormRepositoryProvider).getRecord(recordId);
});

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

/// The generated DMP PDF, ready to preview and share: the downloaded [bytes]
/// plus the originating [result] (signed URL + record id used for a stable
/// share filename).
class DmpPdf {
  const DmpPdf({required this.bytes, required this.result});

  final Uint8List bytes;
  final DmpPdfResult result;
}

/// Generates the DMP PDF for one tenant then downloads its bytes, exposing
/// [AsyncValue] (loading=generating / error / data=ready-to-preview). Keyed by
/// tenant id via [family] so the PDF screen can be opened for any tenant.
/// [regenerate] re-runs the pipeline for the error-state retry button.
///
/// Generation runs on the free tier — there is no entitlement gate here; the
/// DMP wedge must work for every landlord.
class DmpPdfController extends FamilyAsyncNotifier<DmpPdf, String> {
  @override
  Future<DmpPdf> build(String tenantId) => _generate(tenantId);

  DmpFormRepository get _repo => ref.read(dmpFormRepositoryProvider);

  Future<DmpPdf> _generate(String tenantId) async {
    final result = await _repo.generatePdf(tenantId);
    final bytes = await _repo.fetchPdfBytes(result.signedUrl);
    return DmpPdf(bytes: bytes, result: result);
  }

  /// Re-runs generate → download into [state] (error-state retry).
  Future<void> regenerate() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _generate(arg));
  }
}

/// DMP PDF generation state, keyed by tenant id.
final dmpPdfProvider =
    AsyncNotifierProvider.family<DmpPdfController, DmpPdf, String>(
  DmpPdfController.new,
);
