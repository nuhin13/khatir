import 'package:freezed_annotation/freezed_annotation.dart';

part 'dmp_record.freezed.dart';

/// A generated DMP-form record, mirroring the backend `DMPFormRecordSerializer`
/// (`{id, tenant, template_version, pdf_ref, generated_by, generated_at,
/// created_at}`) plus the `signed_url` the detail/generate responses attach
/// (EPIC-05 T-005).
///
/// The record exposes the opaque [pdfRef] and metadata only — **never any field
/// payload or NID**. [signedUrl] is the short-lived download URL used to render
/// or share the A4 PDF; it is absent on payloads that do not include it.
/// Unknown keys are ignored and missing fields degrade to empty / null.
@freezed
abstract class DmpRecord with _$DmpRecord {
  const factory DmpRecord({
    @Default('') String id,
    @Default('') String tenantId,
    @Default('') String templateVersion,
    @Default('') String pdfRef,
    @Default('') String generatedBy,
    DateTime? generatedAt,
    DateTime? createdAt,
    @Default('') String signedUrl,
  }) = _DmpRecord;

  /// Parses a record payload (record fields possibly with a sibling
  /// `signed_url`). Ids stringify; timestamps tolerate null.
  static DmpRecord fromJson(Map<String, dynamic> json) => DmpRecord(
        id: json['id']?.toString() ?? '',
        tenantId: json['tenant']?.toString() ?? '',
        templateVersion: json['template_version']?.toString() ?? '',
        pdfRef: json['pdf_ref']?.toString() ?? '',
        generatedBy: json['generated_by']?.toString() ?? '',
        generatedAt: _toDate(json['generated_at']),
        createdAt: _toDate(json['created_at']),
        signedUrl: json['signed_url']?.toString() ?? '',
      );

  /// Parses the `POST …/dmpform/pdf` envelope (`{record, signed_url}`): the
  /// nested `record` carries the metadata and the top-level `signed_url` is
  /// folded onto the record. Tolerates an absent/empty `record`.
  static DmpRecord fromGenerateJson(Map<String, dynamic> json) {
    final record = json['record'];
    final base = record is Map<String, dynamic> ? record : const <String, dynamic>{};
    return fromJson(<String, dynamic>{
      ...base,
      'signed_url': json['signed_url'],
    });
  }

  static DateTime? _toDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
