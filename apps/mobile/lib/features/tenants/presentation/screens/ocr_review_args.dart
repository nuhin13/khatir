import '../../data/models/extracted_tenant.dart';

/// Typed navigation payload handed to the OCR review screen (T-011) on a
/// successful capture+extract (T-010). Carried via go_router `extra` so the
/// review screen receives the already-extracted fields + `photo_ref` without
/// re-uploading, plus the optional target unit id for the downstream save.
///
/// The review screen and its route land in T-011; this carrier (and the route
/// name constant) is defined here so the capture screen can navigate to it.
class OcrReviewArgs {
  const OcrReviewArgs({required this.extracted, this.unitId});

  /// The editable fields + `photo_ref` returned by `POST /tenants/ocr`.
  final ExtractedTenant extracted;

  /// Optional target unit id threaded from the add-tenant chooser.
  final String? unitId;

  /// Route name of the OCR review screen (registered with the router in T-011).
  static const String routeName = 'tenantsAddOcrReview';

  /// Sub-route path segment under `/tenants/add/ocr`.
  static const String routePath = 'review';
}

/// One family member captured in the review screen's sub-form (T-011, the
/// inline slice ahead of the reusable T-015 widget). Plain value type so it can
/// flow into the shared save action (T-016) and on to the DMP form.
class FamilyMemberDraft {
  const FamilyMemberDraft({required this.name, required this.relation});

  final String name;
  final String relation;

  @override
  bool operator ==(Object other) =>
      other is FamilyMemberDraft &&
      other.name == name &&
      other.relation == relation;

  @override
  int get hashCode => Object.hash(name, relation);
}

/// The landlord-confirmed tenant fields emitted when the OCR review screen's
/// proceed button is tapped. This is the seam the shared save action (T-016)
/// consumes: it carries the *edited* (never the raw OCR) values, the family
/// list, the opaque `photoRef`, and the optional target unit id.
///
/// OCR is never trusted blindly — these are the values the user verified, not
/// the extracted ones (T-011 §2).
class TenantReviewDraft {
  const TenantReviewDraft({
    required this.name,
    required this.nidNumber,
    required this.dob,
    required this.address,
    required this.family,
    required this.photoRef,
    this.unitId,
  });

  final String name;
  final String nidNumber;
  final String dob;
  final String address;
  final List<FamilyMemberDraft> family;
  final String photoRef;
  final String? unitId;
}
