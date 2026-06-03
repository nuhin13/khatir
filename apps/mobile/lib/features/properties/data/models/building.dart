import 'package:freezed_annotation/freezed_annotation.dart';

import 'property_enums.dart';

part 'building.freezed.dart';

/// A building owned by a landlord, mirroring `GET /api/v1/buildings/{id}`
/// (`{id, owner_id, name, area, address, lat, lng, created_at, updated_at}`).
///
/// `lat`/`lng` arrive as decimal **strings** (DRF `DecimalField`) or `null`;
/// they are parsed to [double] here. [area] is the typed [Area] enum, so a
/// static [fromJson] (not a codegen factory) handles the wire→typed mapping.
/// Unknown keys are ignored.
@freezed
abstract class Building with _$Building {
  const factory Building({
    required String id,
    String? ownerId,
    required String name,
    Area? area,
    required String address,
    double? lat,
    double? lng,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Building;

  /// Parses a building payload. `lat`/`lng`/timestamps tolerate missing/null.
  static Building fromJson(Map<String, dynamic> json) => Building(
        id: json['id']?.toString() ?? '',
        ownerId: json['owner_id']?.toString(),
        name: json['name'] as String? ?? '',
        area: Area.fromWire(json['area'] as String?),
        address: json['address'] as String? ?? '',
        lat: _toDouble(json['lat']),
        lng: _toDouble(json['lng']),
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _toDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
