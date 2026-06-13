import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/models.dart';
import 'models/tenant_enums.dart';

/// Network access for the tenant self-service endpoints (EPIC-19 T-002).
///
/// All paths are scoped to the authenticated tenant via the JWT carried by the
/// app's Dio client — no tenant id ever appears in a request body or path.
/// Foreign or unknown ids surface as [ApiException] with `statusCode == 404`
/// (never 403, because /me/ paths always resolve to the caller's own data or
/// nothing).
///
/// When the backend endpoint is not yet implemented the call falls through to a
/// mock response so the Flutter layer can be developed independently.
class TenantRepository {
  const TenantRepository(this._dio);

  final Dio _dio;

  // ── lease ──────────────────────────────────────────────────────────────--

  /// `GET /me/lease` — the caller's active lease. Returns null when the tenant
  /// has no active lease (204 / empty body).
  Future<TenantLease?> myLease() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.myLease);
      final data = res.data;
      if (data == null || data.isEmpty) return null;
      return TenantLease.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _asApiException(e);
    }
  }

  // ── rent ───────────────────────────────────────────────────────────────--

  /// `GET /me/rent` — the caller's current-month rent status. Returns null
  /// when there is no active rent record.
  Future<TenantRent?> myRent() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.myRent);
      final data = res.data;
      if (data == null || data.isEmpty) return null;
      return TenantRent.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _asApiException(e);
    }
  }

  /// `POST /me/rent/{id}/pay` — submit proof of payment for a rent period.
  /// [proofType] is the type of proof (screenshot / txn_id / note).
  /// [value] is the transaction id or note text. [photoRef] is the object
  /// storage key of the uploaded screenshot (optional).
  Future<TenantRent> submitProof({
    required String rentId,
    required PayProofType proofType,
    String? value,
    String? photoRef,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.myRentPay(rentId),
        data: <String, dynamic>{
          'proof_type': proofType.wire,
          if (value != null) 'value': value,
          if (photoRef != null) 'photo_ref': photoRef,
        },
      );
      return TenantRent.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  // ── receipts ───────────────────────────────────────────────────────────--

  /// `GET /me/receipts` — the caller's verified receipt list (all pages
  /// collapsed for the initial implementation; pagination added in a later
  /// pass). Returns an empty list when there are no receipts.
  Future<List<TenantReceipt>> myReceipts() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.myReceipts,
      );
      final data = res.data ?? const <String, dynamic>{};
      final results = data['results'];
      if (results is! List) return const <TenantReceipt>[];
      return results
          .whereType<Map<String, dynamic>>()
          .map(TenantReceipt.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  // ── record / rating ────────────────────────────────────────────────────--

  /// `GET /me/record` — the caller's private good-tenant record. Returns null
  /// when no record has been created yet.
  Future<TenantRecord?> myRecord() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.myRecord);
      final data = res.data;
      if (data == null || data.isEmpty) return null;
      return TenantRecord.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _asApiException(e);
    }
  }

  /// `POST /me/record` — create the private good-tenant record for the first
  /// time. [rating] is 1–5 stars; [notes] is the private memo; [consent]
  /// controls future sharing (default: private). Returns the created record.
  Future<TenantRecord> createRecord({
    required int rating,
    String notes = '',
    RecordConsent consent = RecordConsent.private,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.myRecord,
        data: <String, dynamic>{
          'rating': rating,
          'notes': notes,
          'consent': consent.wire,
        },
      );
      return TenantRecord.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `PATCH /me/record` — update the private good-tenant record. Only the
  /// supplied fields are sent. Returns the updated record.
  Future<TenantRecord> updateRecord({
    int? rating,
    String? notes,
    RecordConsent? consent,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.myRecord,
        data: <String, dynamic>{
          if (rating != null) 'rating': rating,
          if (notes != null) 'notes': notes,
          if (consent != null) 'consent': consent.wire,
        },
      );
      return TenantRecord.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  // ── maintenance reports ────────────────────────────────────────────────--

  /// `POST /api/v1/maintenance/reports` — submit a maintenance report to the
  /// landlord's queue. [description] is required; [category] and [photoRef]
  /// are optional. Returns the created report.
  Future<TenantMaintenanceReport> reportMaintenance({
    required String description,
    TenantMaintenanceCategory category = TenantMaintenanceCategory.other,
    String? photoRef,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.myMaintenanceReports,
        data: <String, dynamic>{
          'description': description,
          'category': category.wire,
          if (photoRef != null) 'photo_ref': photoRef,
        },
      );
      return TenantMaintenanceReport.fromJson(
        res.data ?? const <String, dynamic>{},
      );
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `GET /api/v1/maintenance/reports` — the caller's maintenance reports.
  Future<List<TenantMaintenanceReport>> myMaintenanceReports() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.myMaintenanceReports,
      );
      final data = res.data ?? const <String, dynamic>{};
      final results = data['results'];
      if (results is! List) return const <TenantMaintenanceReport>[];
      return results
          .whereType<Map<String, dynamic>>()
          .map(TenantMaintenanceReport.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  ApiException _asApiException(DioException e) {
    final err = e.error;
    return err is ApiException ? err : ApiException.fromDio(e);
  }
}
