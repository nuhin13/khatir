import 'package:freezed_annotation/freezed_annotation.dart';

part 'lease_document.freezed.dart';

/// Document status lifecycle. Wire values match the backend enum.
///
/// A document starts as [draft] while clauses are being reviewed, and
/// becomes [final_] once the landlord approves it for signing. The Dart
/// identifier uses a trailing underscore to avoid clashing with the reserved
/// word `final`; the wire value is `'final'`.
@JsonEnum(valueField: 'wire')
enum LeaseDocumentStatus {
  draft('draft'),
  final_('final');

  const LeaseDocumentStatus(this.wire);

  /// The lowercase value sent over the wire.
  final String wire;

  /// Parses a wire value. Unknown/absent values degrade to [draft].
  static LeaseDocumentStatus fromWire(String? value) {
    if (value == null) return LeaseDocumentStatus.draft;
    for (final s in LeaseDocumentStatus.values) {
      if (s.wire == value) return s;
    }
    return LeaseDocumentStatus.draft;
  }
}

/// A single clause within a lease document, mirroring the backend
/// `LeaseDocumentClauseSerializer`
/// (`{id, title, content, is_required, sort_order}`).
///
/// Required clauses ([isRequired] == true) must always be present in the
/// final document; optional clauses can be toggled by the landlord.
@freezed
abstract class LeaseDocumentClause with _$LeaseDocumentClause {
  const factory LeaseDocumentClause({
    required String id,
    @Default('') String title,
    @Default('') String content,
    @Default(false) bool isRequired,
    @Default(0) int sortOrder,
  }) = _LeaseDocumentClause;

  /// Parses a clause payload. Tolerates missing/null fields gracefully.
  static LeaseDocumentClause fromJson(Map<String, dynamic> json) =>
      LeaseDocumentClause(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        isRequired: json['is_required'] as bool? ?? false,
        sortOrder: _toInt(json['sort_order']),
      );

  /// Serialises this clause to the wire shape expected by PATCH requests.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'content': content,
        'is_required': isRequired,
        'sort_order': sortOrder,
      };
}

/// A lease document, mirroring the backend `LeaseDocumentSerializer`
/// (`{id, lease_id, status, clauses, disclaimer, pdf_url,
///   created_at, updated_at}`).
///
/// The document is generated server-side from a template; the client reviews
/// and optionally edits the [clauses], then the server renders the [pdfUrl].
@freezed
abstract class LeaseDocument with _$LeaseDocument {
  const factory LeaseDocument({
    required String id,
    @Default('') String leaseId,
    @Default(LeaseDocumentStatus.draft) LeaseDocumentStatus status,
    @Default(<LeaseDocumentClause>[]) List<LeaseDocumentClause> clauses,
    @Default('') String disclaimer,
    @Default('') String pdfUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _LeaseDocument;

  /// Parses a lease-document payload. Tolerates missing/null fields.
  static LeaseDocument fromJson(Map<String, dynamic> json) => LeaseDocument(
        id: json['id']?.toString() ?? '',
        leaseId: json['lease_id']?.toString() ?? '',
        status: LeaseDocumentStatus.fromWire(json['status'] as String?),
        clauses: _parseClauses(json['clauses']),
        disclaimer: json['disclaimer'] as String? ?? '',
        pdfUrl: json['pdf_url'] as String? ?? '',
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );
}

// ── Private helpers ────────────────────────────────────────────────────────

List<LeaseDocumentClause> _parseClauses(Object? value) {
  if (value is! List) return const <LeaseDocumentClause>[];
  return value
      .whereType<Map<String, dynamic>>()
      .map(LeaseDocumentClause.fromJson)
      .toList(growable: false);
}

int _toInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

DateTime? _toDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
