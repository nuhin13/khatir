import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/manager_models.dart';

/// Network access for the manager (EPIC-22) feature.
///
/// Each method maps 1-to-1 to a backend endpoint; errors are surfaced as
/// [ApiException] (via the dio interceptor chain or [_asApiException]).
/// The constructor takes a plain [Dio] so the repository stays testable with a
/// mock client.
class ManagerRepository {
  const ManagerRepository(this._dio);

  final Dio _dio;

  // -------------------------------------------------------------------------
  // Owners
  // -------------------------------------------------------------------------

  /// `GET /api/v1/manager/owners` — list owners actively linked to this manager.
  ///
  /// Returns every [LinkedOwner] regardless of [LinkedOwner.status] (active,
  /// pending, revoked); callers may filter by status locally.
  Future<List<LinkedOwner>> listOwners() async {
    try {
      final res = await _dio.get<List<dynamic>>(
        ApiEndpoints.managerOwners,
      );
      final data = res.data ?? const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(LinkedOwner.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /api/v1/manager/owners/request` — send a link request to an owner.
  ///
  /// [ownerPhone] is the owner's registered phone number; [ownerName] is the
  /// display name used in the invitation; [permissions] is the list of
  /// permission keys requested (e.g. `['read_units', 'collect_rent']`).
  Future<void> requestOwner({
    required String ownerPhone,
    required String ownerName,
    required List<String> permissions,
  }) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.managerOwnersRequest,
        data: <String, dynamic>{
          'owner_phone': ownerPhone,
          'owner_name': ownerName,
          'permissions': permissions,
        },
      );
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  // -------------------------------------------------------------------------
  // Dashboard
  // -------------------------------------------------------------------------

  /// `GET /api/v1/manager/dashboard` — portfolio-wide aggregates.
  ///
  /// The payload includes an embedded [LinkedOwner] list so the overview screen
  /// requires only this single call.
  Future<ManagerDashboard> fetchDashboard() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.managerDashboard,
      );
      return ManagerDashboard.fromJson(
        res.data ?? const <String, dynamic>{},
      );
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  // -------------------------------------------------------------------------
  // Team
  // -------------------------------------------------------------------------

  /// `GET /api/v1/manager/team` — list this manager's team members.
  Future<List<TeamMember>> listTeam() async {
    try {
      final res = await _dio.get<List<dynamic>>(
        ApiEndpoints.managerTeam,
      );
      final data = res.data ?? const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(TeamMember.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /api/v1/manager/team` — invite a new team member.
  ///
  /// [phone] must match an existing user account; [role] is one of
  /// `'accountant'` | `'assistant'` | `'viewer'` | `'sub_manager'`.
  /// [scopeOwnerIds] restricts access to a subset of linked owners (empty =
  /// full scope).
  Future<TeamMember> addTeamMember({
    required String phone,
    required String name,
    required String role,
    List<String>? scopeOwnerIds,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.managerTeam,
        data: <String, dynamic>{
          'phone': phone,
          'name': name,
          'role': role,
          if (scopeOwnerIds != null) 'scope_owner_ids': scopeOwnerIds,
        },
      );
      return TeamMember.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `DELETE /api/v1/manager/team/{id}` — remove a team member.
  Future<void> removeTeamMember(String memberId) async {
    try {
      await _dio.delete<void>(ApiEndpoints.managerTeamMember(memberId));
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  // -------------------------------------------------------------------------
  // Reports
  // -------------------------------------------------------------------------

  /// `GET /api/v1/manager/report/{ownerId}` — read the cached report for an
  /// owner.  Returns the latest snapshot; [OwnerReport.pdfUrl] is null until
  /// [generateOwnerReport] has been called at least once.
  Future<OwnerReport> fetchOwnerReport(String ownerId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.managerReport(ownerId),
      );
      return OwnerReport.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /api/v1/manager/report/{ownerId}/generate` — trigger PDF generation
  /// for an owner's report.
  ///
  /// Returns the updated [OwnerReport] which now carries a signed [OwnerReport.pdfUrl].
  Future<OwnerReport> generateOwnerReport(String ownerId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.managerReportGenerate(ownerId),
      );
      return OwnerReport.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Re-uses an [ApiException] already attached by the error interceptor, or
  /// wraps the raw [DioException] as a fallback.
  ApiException _asApiException(DioException e) {
    final err = e.error;
    return err is ApiException ? err : ApiException.fromDio(e);
  }
}
