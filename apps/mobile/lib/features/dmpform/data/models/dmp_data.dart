import 'package:freezed_annotation/freezed_annotation.dart';

part 'dmp_data.freezed.dart';

/// The assembled DMP-form data for the preview, mirroring the backend assembler
/// `DmpData` shape returned by `GET /api/v1/tenants/{id}/dmpform` (EPIC-05
/// T-004).
///
/// The **full NID is never on the wire** — the data endpoint masks it
/// server-side, so [nidNumber] here is already masked (`**** **** 7788`). The
/// full value appears only in the generated PDF, produced server-side (T-005).
/// Unknown keys are ignored and every field tolerates an absent value so a
/// sparsely-filled tenant still parses cleanly.
@freezed
abstract class DmpData with _$DmpData {
  const factory DmpData({
    @Default('') String tenantName,
    @Default('') String nidNumber,
    @Default('') String dob,
    @Default('') String permanentAddress,
    @Default('') String presentAddress,
    @Default('') String buildingAddress,
    @Default('') String buildingArea,
    @Default('') String landlordName,
    @Default('') String landlordPhone,
    @Default(<DmpFamilyMemberData>[]) List<DmpFamilyMemberData> familyMembers,
  }) = _DmpData;

  /// Parses the assembled DMP payload. Every field degrades to an empty string /
  /// empty list when absent; `family_members` is read nested.
  static DmpData fromJson(Map<String, dynamic> json) => DmpData(
        tenantName: _str(json['tenant_name']),
        nidNumber: _str(json['nid_number']),
        dob: _str(json['dob']),
        permanentAddress: _str(json['permanent_address']),
        presentAddress: _str(json['present_address']),
        buildingAddress: _str(json['building_address']),
        buildingArea: _str(json['building_area']),
        landlordName: _str(json['landlord_name']),
        landlordPhone: _str(json['landlord_phone']),
        familyMembers: _toFamily(json['family_members']),
      );

  static String _str(Object? value) => value?.toString() ?? '';

  static List<DmpFamilyMemberData> _toFamily(Object? value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(DmpFamilyMemberData.fromJson)
          .toList(growable: false);
    }
    return const <DmpFamilyMemberData>[];
  }
}

/// A household member as it appears on the assembled DMP data (`{name,
/// relation}`), mirroring the backend `FamilyMemberData`.
@freezed
abstract class DmpFamilyMemberData with _$DmpFamilyMemberData {
  const factory DmpFamilyMemberData({
    @Default('') String name,
    @Default('') String relation,
  }) = _DmpFamilyMemberData;

  /// Parses one `{name, relation}` member map; missing keys degrade to empty.
  static DmpFamilyMemberData fromJson(Map<String, dynamic> json) =>
      DmpFamilyMemberData(
        name: json['name']?.toString() ?? '',
        relation: json['relation']?.toString() ?? '',
      );
}
