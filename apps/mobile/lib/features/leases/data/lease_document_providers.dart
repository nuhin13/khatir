import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'lease_document_repository.dart';
import 'models/lease_document.dart';

/// The shared [LeaseDocumentRepository], backed by the app-wide dio client.
final leaseDocumentRepositoryProvider = Provider<LeaseDocumentRepository>(
  (ref) => LeaseDocumentRepository(ref.watch(dioClientProvider)),
);

// ── Lease document controller ─────────────────────────────────────────────--

/// Drives the lifecycle of one lease's document, keyed by lease id.
///
/// [build] fetches `GET /leases/{id}/document`. Callers can trigger server-
/// side generation via [generate] (POST …/document) and submit clause edits
/// via [updateClauses] (PATCH …/document). All mutations write the server
/// response back into [state].
class LeaseDocumentController
    extends FamilyAsyncNotifier<LeaseDocument, String> {
  @override
  Future<LeaseDocument> build(String leaseId) =>
      _repo.getDocument(leaseId);

  LeaseDocumentRepository get _repo =>
      ref.read(leaseDocumentRepositoryProvider);

  /// `POST /leases/{id}/document` — generate the document from the server-side
  /// template. Updates [state] with the generated (draft) document.
  Future<LeaseDocument> generate() async {
    final doc = await _repo.generateDocument(arg);
    state = AsyncValue.data(doc);
    return doc;
  }

  /// `PATCH /leases/{id}/document` — submit edited clause list.
  /// Updates [state] with the server's response (which may reorder/validate
  /// clauses).
  Future<LeaseDocument> updateClauses(
    List<LeaseDocumentClause> clauses,
  ) async {
    final doc = await _repo.updateDocument(arg, clauses);
    state = AsyncValue.data(doc);
    return doc;
  }
}

/// One lease's document state, keyed by lease id.
final leaseDocumentControllerProvider = AsyncNotifierProvider.family<
    LeaseDocumentController, LeaseDocument, String>(
  LeaseDocumentController.new,
);
