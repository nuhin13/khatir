import 'package:freezed_annotation/freezed_annotation.dart';

part 'extracted_tenant.freezed.dart';

/// One extracted value plus its optional 0–1 confidence, mirroring the backend
/// `_ExtractedFieldSerializer` (`{value, confidence}`). The review UI (T-011)
/// uses [confidence] to flag low-confidence values for the user to confirm.
@freezed
abstract class ExtractedField with _$ExtractedField {
  const factory ExtractedField({
    String? value,
    double? confidence,
  }) = _ExtractedField;

  /// Parses one `{value, confidence}` map. A bare/absent map yields an empty
  /// field (both null) so a partial OCR result never throws.
  static ExtractedField fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    return ExtractedField(
      value: map['value']?.toString(),
      confidence: _toDouble(map['confidence']),
    );
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

/// The editable result returned by `POST /tenants/ocr`
/// (`{name, nid_number, dob, address, photo_ref}`), where each field carries a
/// value + confidence. The tenant is **not** created yet — these fields flow to
/// the OCR review screen (T-011) for confirmation before save.
///
/// [photoRef] is the opaque server-side handle for the encrypted NID image; the
/// raw image bytes are never part of this shape (privacy — the image is
/// discarded on the device after upload, self-review §14).
@freezed
abstract class ExtractedTenant with _$ExtractedTenant {
  const factory ExtractedTenant({
    required ExtractedField name,
    required ExtractedField nidNumber,
    required ExtractedField dob,
    required ExtractedField address,
    required String photoRef,
  }) = _ExtractedTenant;

  /// Parses the OCR response envelope. Unknown keys are ignored; missing field
  /// maps degrade to empty [ExtractedField]s.
  static ExtractedTenant fromJson(Map<String, dynamic> json) => ExtractedTenant(
        name: ExtractedField.fromJson(_map(json['name'])),
        nidNumber: ExtractedField.fromJson(_map(json['nid_number'])),
        dob: ExtractedField.fromJson(_map(json['dob'])),
        address: ExtractedField.fromJson(_map(json['address'])),
        photoRef: json['photo_ref']?.toString() ?? '',
      );

  static Map<String, dynamic>? _map(Object? value) =>
      value is Map<String, dynamic> ? value : null;
}
