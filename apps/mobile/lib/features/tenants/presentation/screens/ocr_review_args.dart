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
