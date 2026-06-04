import 'package:freezed_annotation/freezed_annotation.dart';

import 'family_member.dart';
import 'tenant_enums.dart';

part 'tenant.freezed.dart';

/// A persisted tenant identity record, mirroring the masked `TenantSerializer`
/// (`{id, name, nid_number_masked, dob, address, photo_ref, verification_status,
/// verified_at, is_app_user, family_members, created_at, updated_at}`).
///
/// The **full NID is never on the wire** — only [nidNumberMasked] (`****7788`)
/// is exposed; there is no plaintext NID field client-side (DMP generation is
/// server-side, T-014 §15). [familyMembers] are read nested. Unknown keys are
/// ignored; nullable timestamps/dates tolerate absent values.
@freezed
abstract class Tenant with _$Tenant {
  const factory Tenant({
    required String id,
    required String name,
    @Default('') String nidNumberMasked,
    DateTime? dob,
    @Default('') String address,
    @Default('') String photoRef,
    @Default(VerificationStatus.unverified)
    VerificationStatus verificationStatus,
    DateTime? verifiedAt,
    @Default(false) bool isAppUser,
    @Default(<FamilyMember>[]) List<FamilyMember> familyMembers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Tenant;

  /// Parses a masked tenant payload. `dob`/timestamps tolerate null;
  /// `family_members` defaults to empty.
  static Tenant fromJson(Map<String, dynamic> json) => Tenant(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        nidNumberMasked: json['nid_number_masked'] as String? ?? '',
        dob: _toDate(json['dob']),
        address: json['address'] as String? ?? '',
        photoRef: json['photo_ref'] as String? ?? '',
        verificationStatus:
            VerificationStatus.fromWire(json['verification_status'] as String?),
        verifiedAt: _toDate(json['verified_at']),
        isAppUser: json['is_app_user'] as bool? ?? false,
        familyMembers: _toFamily(json['family_members']),
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );

  static List<FamilyMember> _toFamily(Object? value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(FamilyMember.fromJson)
          .toList(growable: false);
    }
    return const <FamilyMember>[];
  }

  static DateTime? _toDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
