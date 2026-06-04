import 'package:freezed_annotation/freezed_annotation.dart';

part 'family_member.freezed.dart';

/// A household member listed on the DMP (police) form, mirroring the backend
/// `FamilyMemberSerializer` (`{id, name, relation}`). Written nested under a
/// [Tenant] on create/update and read back nested on the tenant payload.
///
/// [id] is server-assigned and absent on a freshly-drafted member (the create
/// path sends only `name`/`relation`).
@freezed
abstract class FamilyMember with _$FamilyMember {
  const factory FamilyMember({
    String? id,
    required String name,
    required String relation,
  }) = _FamilyMember;

  /// Parses one `{id, name, relation}` member map. Unknown keys are ignored;
  /// missing name/relation degrade to empty strings.
  static FamilyMember fromJson(Map<String, dynamic> json) => FamilyMember(
        id: json['id']?.toString(),
        name: json['name'] as String? ?? '',
        relation: json['relation'] as String? ?? '',
      );

  /// The write shape (`{name, relation}`) sent nested on create/update. The
  /// server assigns [id], so it is never part of the request body.
  static Map<String, dynamic> toCreateJson(FamilyMember member) =>
      <String, dynamic>{
        'name': member.name,
        'relation': member.relation,
      };
}
