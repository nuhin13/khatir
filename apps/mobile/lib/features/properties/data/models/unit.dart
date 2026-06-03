import 'package:freezed_annotation/freezed_annotation.dart';

import 'property_enums.dart';

part 'unit.freezed.dart';

/// One rentable unit inside a building, mirroring `GET /api/v1/units/{id}`
/// (`{id, building_id, label, type, rent, amenities, status, available_from,
/// created_at, updated_at}`).
///
/// `rent` arrives as a decimal **string** (DRF `DecimalField`) → parsed to
/// [double]. [type]/[status] are the typed enums, so a static [fromJson]
/// handles the wire→typed mapping. Unknown keys are ignored.
@freezed
abstract class Unit with _$Unit {
  const factory Unit({
    required String id,
    String? buildingId,
    required String label,
    UnitType? type,
    double? rent,
    @Default(<String>[]) List<String> amenities,
    UnitStatus? status,
    DateTime? availableFrom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Unit;

  /// Parses a unit payload. `rent`/`available_from`/timestamps tolerate null.
  static Unit fromJson(Map<String, dynamic> json) => Unit(
        id: json['id']?.toString() ?? '',
        buildingId: json['building_id']?.toString(),
        label: json['label'] as String? ?? '',
        type: UnitType.fromWire(json['type'] as String?),
        rent: _toDouble(json['rent']),
        amenities: _toStringList(json['amenities']),
        status: UnitStatus.fromWire(json['status'] as String?),
        availableFrom: _toDate(json['available_from']),
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static List<String> _toStringList(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList(growable: false);
    }
    return const <String>[];
  }

  static DateTime? _toDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
