import 'package:freezed_annotation/freezed_annotation.dart';

import 'warning_enums.dart';

part 'models.freezed.dart';

/// A private warning notice issued by a landlord to their own tenant,
/// mirroring the backend `WarningSerializer`
/// (`{id, lease_id, tenant_id, landlord_id, warning_type, reason,
///   issued_at, notice_ref, acknowledged_at}`).
///
/// Strictly private to the landlord–tenant relationship: no cross-landlord
/// visibility, no public path, no aggregation across landlords. The server
/// enforces scoping via `for_user`; a foreign/unknown lease id always resolves
/// to 404 (never 403). [noticeRef] holds the signed PDF URL once generated.
@freezed
abstract class Warning with _$Warning {
  const factory Warning({
    required String id,
    @Default('') String leaseId,
    @Default('') String tenantId,
    @Default('') String landlordId,
    @Default(WarningType.other) WarningType warningType,
    @Default('') String reason,
    DateTime? issuedAt,
    @Default('') String noticeRef,
    DateTime? acknowledgedAt,
  }) = _Warning;

  /// Parses a warning payload. [warningType] degrades to [WarningType.other];
  /// timestamps tolerate null.
  static Warning fromJson(Map<String, dynamic> json) => Warning(
        id: json['id']?.toString() ?? '',
        leaseId: json['lease_id']?.toString() ?? '',
        tenantId: json['tenant_id']?.toString() ?? '',
        landlordId: json['landlord_id']?.toString() ?? '',
        warningType: WarningType.fromWire(json['warning_type'] as String?),
        reason: json['reason'] as String? ?? '',
        issuedAt: _toDate(json['issued_at']),
        noticeRef: json['notice_ref'] as String? ?? '',
        acknowledgedAt: _toDate(json['acknowledged_at']),
      );
}

/// The result of generating a warning notice PDF, mirroring the backend
/// `WarningNoticeSerializer` (`{warning_id, notice_ref, signed_url}`).
/// The [signedUrl] is a short-lived download URL for the PDF bytes.
@freezed
abstract class WarningNotice with _$WarningNotice {
  const factory WarningNotice({
    required String warningId,
    @Default('') String noticeRef,
    @Default('') String signedUrl,
  }) = _WarningNotice;

  static WarningNotice fromJson(Map<String, dynamic> json) => WarningNotice(
        warningId: json['warning_id']?.toString() ?? '',
        noticeRef: json['notice_ref'] as String? ?? '',
        signedUrl: json['signed_url'] as String? ?? '',
      );
}

DateTime? _toDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
