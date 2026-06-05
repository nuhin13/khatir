/// The result of generating a DMP PDF (EPIC-05 T-008), mirroring the backend
/// `POST /api/v1/tenants/{id}/dmpform/pdf` response (T-005
/// `GeneratePdfResponseSerializer`): a generated `record` plus a `signed_url`.
///
/// Only the fields the mobile client needs are kept: the [signedUrl] used to
/// download/render the A4 PDF, and the [recordId] for a stable share filename.
/// The signed URL is short-lived (TTL ~1h) so the bytes are fetched promptly.
class DmpPdfResult {
  const DmpPdfResult({required this.signedUrl, this.recordId = ''});

  /// Time-limited URL to download/render the generated PDF.
  final String signedUrl;

  /// Generated record id (used to name the shared file), empty when absent.
  final String recordId;

  /// Parses the generate response. Tolerates an absent/empty `record`.
  static DmpPdfResult fromJson(Map<String, dynamic> json) {
    final record = json['record'];
    final recordId = record is Map<String, dynamic>
        ? (record['id']?.toString() ?? '')
        : '';
    return DmpPdfResult(
      signedUrl: json['signed_url']?.toString() ?? '',
      recordId: recordId,
    );
  }
}
