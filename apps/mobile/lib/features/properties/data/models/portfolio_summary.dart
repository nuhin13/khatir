import 'package:freezed_annotation/freezed_annotation.dart';

import 'property_enums.dart';

part 'portfolio_summary.freezed.dart';

/// Per-building rollup in the portfolio list, mirroring one entry of
/// `GET /api/v1/portfolio` → `buildings[]`
/// (`{id, name, area, total_units, occupied, vacant, maintenance, total_rent}`).
///
/// `total_rent` arrives as a decimal **string** → parsed to [double].
@freezed
abstract class BuildingSummary with _$BuildingSummary {
  const factory BuildingSummary({
    required String id,
    required String name,
    Area? area,
    @Default(0) int totalUnits,
    @Default(0) int occupied,
    @Default(0) int vacant,
    @Default(0) int maintenance,
    @Default(0) double totalRent,
  }) = _BuildingSummary;

  /// Parses one building-summary entry.
  static BuildingSummary fromJson(Map<String, dynamic> json) => BuildingSummary(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        area: Area.fromWire(json['area'] as String?),
        totalUnits: _toInt(json['total_units']),
        occupied: _toInt(json['occupied']),
        vacant: _toInt(json['vacant']),
        maintenance: _toInt(json['maintenance']),
        totalRent: _toDouble(json['total_rent']),
      );
}

/// Grand totals across the whole portfolio, mirroring `portfolio.totals`
/// (`{buildings, total_units, occupied, vacant, maintenance, total_rent}`).
@freezed
abstract class PortfolioTotals with _$PortfolioTotals {
  const factory PortfolioTotals({
    @Default(0) int buildings,
    @Default(0) int totalUnits,
    @Default(0) int occupied,
    @Default(0) int vacant,
    @Default(0) int maintenance,
    @Default(0) double totalRent,
  }) = _PortfolioTotals;

  /// Parses the top-level totals object.
  static PortfolioTotals fromJson(Map<String, dynamic> json) => PortfolioTotals(
        buildings: _toInt(json['buildings']),
        totalUnits: _toInt(json['total_units']),
        occupied: _toInt(json['occupied']),
        vacant: _toInt(json['vacant']),
        maintenance: _toInt(json['maintenance']),
        totalRent: _toDouble(json['total_rent']),
      );
}

/// The full portfolio payload: per-building summaries + grand totals,
/// mirroring `GET /api/v1/portfolio` (`{buildings: [...], totals: {...}}`).
@freezed
abstract class PortfolioSummary with _$PortfolioSummary {
  const factory PortfolioSummary({
    @Default(<BuildingSummary>[]) List<BuildingSummary> buildings,
    @Default(PortfolioTotals()) PortfolioTotals totals,
  }) = _PortfolioSummary;

  /// Parses the portfolio payload.
  static PortfolioSummary fromJson(Map<String, dynamic> json) {
    final rawBuildings = json['buildings'];
    final buildings = rawBuildings is List
        ? rawBuildings
            .whereType<Map<String, dynamic>>()
            .map(BuildingSummary.fromJson)
            .toList(growable: false)
        : const <BuildingSummary>[];
    final rawTotals = json['totals'];
    final totals = rawTotals is Map<String, dynamic>
        ? PortfolioTotals.fromJson(rawTotals)
        : const PortfolioTotals();
    return PortfolioSummary(buildings: buildings, totals: totals);
  }
}

int _toInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _toDouble(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
