/// The assembled DMP-form data shown on the preview screen (EPIC-05 T-007),
/// mirroring the backend preview shape returned by
/// `GET /api/v1/tenants/{id}/dmpform` (T-004 / assembler `DmpData`).
///
/// The **full NID is never on the wire** — the preview endpoint masks it
/// server-side, so [nidNumber] here is already masked (`**** **** 7788`). The
/// full value appears only in the generated PDF, produced server-side (T-005).
/// Unknown keys are ignored and every field tolerates an absent value so a
/// sparsely-filled tenant still renders cleanly.
class DmpPreview {
  const DmpPreview({
    this.tenantName = '',
    this.nidNumber = '',
    this.dob = '',
    this.permanentAddress = '',
    this.presentAddress = '',
    this.buildingAddress = '',
    this.buildingArea = '',
    this.landlordName = '',
    this.landlordPhone = '',
    this.familyMembers = const <DmpFamilyMember>[],
  });

  /// Tenant's name.
  final String tenantName;

  /// **Masked** NID (e.g. `**** **** 7788`) — never the full value.
  final String nidNumber;

  /// Date of birth, as the server formatted it (ISO `YYYY-MM-DD` or empty).
  final String dob;

  /// Tenant's permanent address.
  final String permanentAddress;

  /// Tenant's present address.
  final String presentAddress;

  /// Building/rented address.
  final String buildingAddress;

  /// Building area/thana.
  final String buildingArea;

  /// Landlord's name.
  final String landlordName;

  /// Landlord's phone.
  final String landlordPhone;

  /// Household members printed on the form.
  final List<DmpFamilyMember> familyMembers;

  /// Parses the preview payload. Every field degrades to an empty string /
  /// empty list when absent; `family_members` is read nested.
  static DmpPreview fromJson(Map<String, dynamic> json) => DmpPreview(
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

  static List<DmpFamilyMember> _toFamily(Object? value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(DmpFamilyMember.fromJson)
          .toList(growable: false);
    }
    return const <DmpFamilyMember>[];
  }
}

/// A household member as it appears on the DMP preview (`{name, relation}`).
class DmpFamilyMember {
  const DmpFamilyMember({this.name = '', this.relation = ''});

  final String name;
  final String relation;

  static DmpFamilyMember fromJson(Map<String, dynamic> json) =>
      DmpFamilyMember(
        name: json['name']?.toString() ?? '',
        relation: json['relation']?.toString() ?? '',
      );
}
