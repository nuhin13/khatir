import 'package:freezed_annotation/freezed_annotation.dart';

import 'rent_enums.dart';

part 'models.freezed.dart';

/// A persisted rent request, mirroring the backend `RentRequestSerializer`
/// (`{id, lease_id, rent_schedule_id, amount, period, link_token, sent_via,
/// sent_at, status, created_at, updated_at}`).
///
/// The FK ids ([leaseId], [rentScheduleId]), the [linkToken] and [status] are
/// read-only server-side; the client never sets them — the token is minted by
/// the T-002 service. [amount] arrives as a DRF `DecimalField` **string** and is
/// parsed to [double]. [period] is the `YYYY-MM` billing month. Unknown keys are
/// ignored; nullable timestamps tolerate absent values.
@freezed
abstract class RentRequest with _$RentRequest {
  const factory RentRequest({
    required String id,
    @Default('') String leaseId,
    @Default('') String rentScheduleId,
    @Default(0) double amount,
    @Default('') String period,
    @Default('') String linkToken,
    @Default(Channel.whatsapp) Channel sentVia,
    DateTime? sentAt,
    @Default(RentRequestStatus.sent) RentRequestStatus status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _RentRequest;

  /// Parses a rent-request payload. `amount` string tolerates null; `sent_via`
  /// degrades to `whatsapp` and `status` to `sent`; timestamps tolerate null.
  static RentRequest fromJson(Map<String, dynamic> json) => RentRequest(
        id: json['id']?.toString() ?? '',
        leaseId: json['lease_id']?.toString() ?? '',
        rentScheduleId: json['rent_schedule_id']?.toString() ?? '',
        amount: _toDouble(json['amount']),
        period: json['period'] as String? ?? '',
        linkToken: json['link_token'] as String? ?? '',
        sentVia: Channel.fromWire(json['sent_via'] as String?),
        sentAt: _toDate(json['sent_at']),
        status: RentRequestStatus.fromWire(json['status'] as String?),
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );
}

/// Evidence a tenant submits against a rent request, mirroring the backend
/// `PaymentProof` model (`{id, rent_request_id, type, value, photo_ref,
/// submitted_at, created_at, updated_at}`).
///
/// Read-only client-side — proofs are submitted by the tenant via the token web
/// page, never by the landlord app. [value] is a transaction id or note text;
/// [photoRef] points to a screenshot/photo in object storage. [type] degrades to
/// [PaymentProofType.note] on an unknown wire value.
@freezed
abstract class PaymentProof with _$PaymentProof {
  const factory PaymentProof({
    required String id,
    @Default('') String rentRequestId,
    @Default(PaymentProofType.note) PaymentProofType type,
    @Default('') String value,
    @Default('') String photoRef,
    DateTime? submittedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PaymentProof;

  /// Parses a payment-proof payload. `type` degrades to `note`; timestamps
  /// tolerate null.
  static PaymentProof fromJson(Map<String, dynamic> json) => PaymentProof(
        id: json['id']?.toString() ?? '',
        rentRequestId: json['rent_request_id']?.toString() ?? '',
        type: PaymentProofType.fromWire(json['type'] as String?),
        value: json['value'] as String? ?? '',
        photoRef: json['photo_ref'] as String? ?? '',
        submittedAt: _toDate(json['submitted_at']),
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );
}

/// The confirmed, verified payment for a settled rent request, mirroring the
/// backend `Payment` model (`{id, rent_request_id, verified_at, verified_by_id,
/// receipt_ref, created_at, updated_at}`).
///
/// Read-only client-side — a payment is created by the verify/mark-received
/// service, never by the client. [receiptRef] points to the generated receipt
/// PDF in object storage; [verifiedBy] is the landlord/manager who confirmed.
@freezed
abstract class Payment with _$Payment {
  const factory Payment({
    required String id,
    @Default('') String rentRequestId,
    DateTime? verifiedAt,
    @Default('') String verifiedBy,
    @Default('') String receiptRef,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Payment;

  /// Parses a payment payload. Timestamps tolerate null; ids serialize to
  /// strings.
  static Payment fromJson(Map<String, dynamic> json) => Payment(
        id: json['id']?.toString() ?? '',
        rentRequestId: json['rent_request_id']?.toString() ?? '',
        verifiedAt: _toDate(json['verified_at']),
        verifiedBy: json['verified_by_id']?.toString() ??
            json['verified_by']?.toString() ??
            '',
        receiptRef: json['receipt_ref'] as String? ?? '',
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );
}

double _toDouble(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

DateTime? _toDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
