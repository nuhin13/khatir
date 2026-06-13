import 'package:freezed_annotation/freezed_annotation.dart';

part 'verification_result.freezed.dart';

/// The outcome of an EC NID verification call for a tenant.
///
/// Only `status` (matched/not_matched/error) and the opaque `providerRef` are
/// stored — **no raw EC payload fields are ever persisted or returned**.
/// This enforces the privacy gate (T-010): downstream code can display a result
/// badge but can never reconstruct or log any personal data received from the
/// EC service.
///
/// [tenantId] is the Khatir tenant this result belongs to.
/// [status] mirrors [VerificationStatus] as a string so the model stays
/// self-contained (the enum lives in the tenants feature layer; we reference the
/// wire string here to avoid a cross-feature import). Use
/// [VerificationResultStatus] for typed switching.
/// [providerRef] is the opaque reference returned by the backend (non-null on
/// any call that reached the EC service, null when the call errored locally).
/// [verifiedAt] is set by the server on success.
@freezed
abstract class VerificationResult with _$VerificationResult {
  const factory VerificationResult({
    required String tenantId,
    required VerificationResultStatus status,
    @Default('') String providerRef,
    DateTime? verifiedAt,
  }) = _VerificationResult;

  /// Parses the verify-endpoint response.
  ///
  /// The server shape is `{ tenant_id, verification_status, provider_ref,
  /// verified_at }`. Unknown status values degrade to [VerificationResultStatus.error]
  /// so a partial/unexpected response never throws.
  static VerificationResult fromJson(Map<String, dynamic> json) =>
      VerificationResult(
        tenantId: json['tenant_id']?.toString() ?? '',
        status: VerificationResultStatus.fromWire(
          json['verification_status'] as String?,
        ),
        providerRef: json['provider_ref'] as String? ?? '',
        verifiedAt: _toDate(json['verified_at']),
      );

  static DateTime? _toDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

/// Typed verification outcome enum — mirrors `VerificationStatus` wire values
/// but lives in the verification feature so it is self-contained.
enum VerificationResultStatus {
  matched('matched'),
  notMatched('not_matched'),
  error('error');

  const VerificationResultStatus(this.wire);

  /// The lowercase snake_case wire value.
  final String wire;

  /// Parses a wire value. Unknown/absent values degrade to [error].
  static VerificationResultStatus fromWire(String? value) {
    if (value == null) return VerificationResultStatus.error;
    for (final s in VerificationResultStatus.values) {
      if (s.wire == value) return s;
    }
    return VerificationResultStatus.error;
  }
}
