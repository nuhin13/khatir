/// Rent-collection-domain enums. Wire values are lowercase snake_case strings
/// and MUST match `docs/architecture/enums.md` (RentRequestStatus /
/// PaymentProofType / Channel) and the backend `rent/enums.py`. Domain-specific
/// (used only by [RentRequest] / [PaymentProof]), so they live in the owning
/// feature rather than `core/enums`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

/// Lifecycle status of a single ask-for-rent event. Mirrors backend
/// `RentRequestStatus`.
///
/// A request is created/delivered as [sent]; it becomes [proofSubmitted] when
/// the tenant uploads evidence, [verified] once the landlord confirms (creating
/// a Payment + receipt), or [rejected] if the landlord declines it.
@JsonEnum(valueField: 'wire')
enum RentRequestStatus {
  sent('sent'),
  proofSubmitted('proof_submitted'),
  verified('verified'),
  rejected('rejected');

  const RentRequestStatus(this.wire);

  /// The lowercase snake_case value sent over the wire.
  final String wire;

  /// Parses a wire value into a [RentRequestStatus]. Unknown/absent values
  /// degrade to [RentRequestStatus.sent] (the backend default for a new
  /// request) so a partial read never throws.
  static RentRequestStatus fromWire(String? value) {
    if (value == null) return RentRequestStatus.sent;
    for (final status in RentRequestStatus.values) {
      if (status.wire == value) return status;
    }
    return RentRequestStatus.sent;
  }
}

/// The kind of evidence a tenant submits against a rent request. Mirrors backend
/// `PaymentProofType`.
@JsonEnum(valueField: 'wire')
enum PaymentProofType {
  bkashTxn('bkash_txn'),
  nagadTxn('nagad_txn'),
  screenshot('screenshot'),
  photo('photo'),
  note('note');

  const PaymentProofType(this.wire);

  /// The lowercase snake_case value sent over the wire.
  final String wire;

  /// Parses a wire value into a [PaymentProofType]. Unknown/absent values
  /// degrade to [PaymentProofType.note] (the most generic, free-text proof) so a
  /// partial read never throws.
  static PaymentProofType fromWire(String? value) {
    if (value == null) return PaymentProofType.note;
    for (final type in PaymentProofType.values) {
      if (type.wire == value) return type;
    }
    return PaymentProofType.note;
  }
}

/// Delivery channel a rent request was sent through. Mirrors backend `Channel`.
@JsonEnum(valueField: 'wire')
enum Channel {
  inapp('inapp'),
  whatsapp('whatsapp'),
  sms('sms'),
  email('email');

  const Channel(this.wire);

  /// The lowercase snake_case value sent over the wire.
  final String wire;

  /// Parses a wire value into a [Channel]. Unknown/absent values degrade to
  /// [Channel.whatsapp] (the backend default delivery channel) so a partial read
  /// never throws.
  static Channel fromWire(String? value) {
    if (value == null) return Channel.whatsapp;
    for (final channel in Channel.values) {
      if (channel.wire == value) return channel;
    }
    return Channel.whatsapp;
  }
}
