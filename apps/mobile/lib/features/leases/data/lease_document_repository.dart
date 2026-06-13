import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/lease_document.dart';

/// Network access for lease documents (EPIC-06 T-009 endpoints):
/// generate / get / update clauses / render PDF.
///
/// The document is generated server-side from a template tied to the lease;
/// the client reviews/edits clauses, then triggers PDF rendering. The [pdfUrl]
/// returned by [getDocumentPdfBytes] is a short-lived signed URL; the bytes are
/// fetched from it directly (no auth header forwarded to the foreign host).
/// Errors surface as [ApiException].
class LeaseDocumentRepository {
  const LeaseDocumentRepository(this._dio);

  final Dio _dio;

  /// `POST /leases/{id}/document` — generate the lease document from the
  /// server-side template and return the (draft) [LeaseDocument].
  Future<LeaseDocument> generateDocument(String leaseId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.leaseDocument(leaseId),
      );
      return LeaseDocument.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `GET /leases/{id}/document` — retrieve the current lease document.
  ///
  /// Returns the document with its clauses. If no document has been generated
  /// yet the server returns **404**, surfaced as an [ApiException].
  Future<LeaseDocument> getDocument(String leaseId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.leaseDocument(leaseId),
      );
      return LeaseDocument.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `PATCH /leases/{id}/document` — update the document's clauses.
  ///
  /// Sends `{"clauses": [...]}` and returns the updated [LeaseDocument].
  /// Only the [clauses] list is sent; other document fields are immutable from
  /// the client's perspective.
  Future<LeaseDocument> updateDocument(
    String leaseId,
    List<LeaseDocumentClause> clauses,
  ) async {
    final body = <String, dynamic>{
      'clauses': clauses.map((c) => c.toJson()).toList(growable: false),
    };
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.leaseDocument(leaseId),
        data: body,
      );
      return LeaseDocument.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /leases/{id}/document/pdf` — render the lease PDF on the server.
  ///
  /// The server returns `{"pdf_url": "<signed-url>"}`. This method then
  /// fetches the PDF bytes from that signed URL and returns them as a
  /// [Uint8List] ready for display or sharing. The signed URL is absolute and
  /// already authorised; auth headers are not forwarded to the foreign host.
  Future<Uint8List> getDocumentPdfBytes(String leaseId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.leaseDocumentPdf(leaseId),
      );
      final data = res.data ?? const <String, dynamic>{};
      final pdfUrl = data['pdf_url'] as String? ?? '';
      if (pdfUrl.isEmpty) return Uint8List(0);
      return _fetchBytes(pdfUrl);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// Downloads raw bytes from an absolute [url] (signed S3 / CDN link).
  Future<Uint8List> _fetchBytes(String url) async {
    try {
      final res = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(res.data ?? const <int>[]);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  ApiException _asApiException(DioException e) {
    final err = e.error;
    return err is ApiException ? err : ApiException.fromDio(e);
  }
}
