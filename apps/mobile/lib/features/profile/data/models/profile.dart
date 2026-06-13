import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/enums/role.dart';

part 'profile.freezed.dart';

/// The caller's own profile, mirroring `GET /api/v1/profile`
/// (`{id, phone, name, role, language}` — same shape as `/auth/me`).
///
/// Like `SessionUser`, [role] is the typed [Role] enum, so parsing is done in
/// a static [fromJson] method (not a `fromJson` factory) to avoid pulling json
/// codegen in for an enum-typed field.
@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String id,
    String? phone,
    String? name,
    Role? role,
    String? language,
  }) = _Profile;

  /// Parses the `/profile` (or `/auth/me`) payload. Unknown keys are ignored.
  static Profile fromJson(Map<String, dynamic> json) => Profile(
        id: json['id']?.toString() ?? '',
        phone: json['phone'] as String?,
        name: json['name'] as String?,
        role: Role.fromWire(json['role'] as String?),
        language: json['language'] as String?,
      );
}
