import 'package:dio/dio.dart';

import '../../../core/enums/role.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/profile.dart';

/// Network access for the profile feature (T-003): read the caller's own
/// profile via `GET /profile` and apply partial updates via `PATCH /profile`.
///
/// The endpoint is always self-scoped server-side (`request.user`), so no id is
/// sent. Errors are surfaced as [ApiException] (normalised by the dio error
/// interceptor) so callers branch on [ApiException.statusCode].
class ProfileRepository {
  const ProfileRepository(this._dio);

  final Dio _dio;

  /// Fetches the current user's profile.
  Future<Profile> getProfile() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.profile);
      final data = res.data ?? const <String, dynamic>{};
      return Profile.fromJson(data);
    } on DioException catch (e) {
      final err = e.error;
      throw err is ApiException ? err : ApiException.fromDio(e);
    }
  }

  /// Applies a partial profile update. Only the non-null fields are sent
  /// (PATCH semantics); the server validates [role] against the self-selectable
  /// set and [language] against the `bn|en` enum. Returns the updated profile.
  Future<Profile> updateProfile({
    String? name,
    Role? role,
    String? language,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (role != null) 'role': role.wire,
      if (language != null) 'language': language,
    };
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.profile,
        data: body,
      );
      final data = res.data ?? const <String, dynamic>{};
      return Profile.fromJson(data);
    } on DioException catch (e) {
      final err = e.error;
      throw err is ApiException ? err : ApiException.fromDio(e);
    }
  }
}
