import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'building_repository.dart';
import 'models/building.dart';
import 'models/portfolio_summary.dart';
import 'models/property_enums.dart';
import 'models/unit.dart';
import 'portfolio_repository.dart';
import 'unit_repository.dart';

// ── Repositories ────────────────────────────────────────────────────────────

/// The shared [BuildingRepository], backed by the app-wide dio client.
final buildingRepositoryProvider = Provider<BuildingRepository>(
  (ref) => BuildingRepository(ref.watch(dioClientProvider)),
);

/// The shared [UnitRepository], backed by the app-wide dio client.
final unitRepositoryProvider = Provider<UnitRepository>(
  (ref) => UnitRepository(ref.watch(dioClientProvider)),
);

/// The shared [PortfolioRepository], backed by the app-wide dio client.
final portfolioRepositoryProvider = Provider<PortfolioRepository>(
  (ref) => PortfolioRepository(ref.watch(dioClientProvider)),
);

// ── Buildings list ────────────────────────────────────────────────────────--

/// Loads and mutates the caller's buildings list, exposing [AsyncValue].
///
/// [build] fetches `GET /buildings`. The CRUD methods call the repository then
/// re-fetch so the list stays consistent with the server (the source of truth);
/// they return the affected resource for callers that need it.
class BuildingsController extends AsyncNotifier<List<Building>> {
  @override
  Future<List<Building>> build() => _repo.listBuildings();

  BuildingRepository get _repo => ref.read(buildingRepositoryProvider);

  /// Re-fetches the buildings list into [state].
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.listBuildings);
  }

  /// Creates a building, then refreshes the list. Returns the new building.
  Future<Building> create({
    required String name,
    required Area area,
    required String address,
    double? lat,
    double? lng,
  }) async {
    final building = await _repo.createBuilding(
      name: name,
      area: area,
      address: address,
      lat: lat,
      lng: lng,
    );
    await refresh();
    return building;
  }

  /// Partially updates a building, then refreshes the list.
  Future<Building> updateBuilding(
    String id, {
    String? name,
    Area? area,
    String? address,
    double? lat,
    double? lng,
  }) async {
    final building = await _repo.updateBuilding(
      id,
      name: name,
      area: area,
      address: address,
      lat: lat,
      lng: lng,
    );
    await refresh();
    return building;
  }

  /// Deletes a building, then refreshes the list.
  Future<void> delete(String id) async {
    await _repo.deleteBuilding(id);
    await refresh();
  }
}

/// App-wide buildings list state.
final buildingsProvider =
    AsyncNotifierProvider<BuildingsController, List<Building>>(
  BuildingsController.new,
);

/// One building by id — `GET /buildings/{id}`. Keyed by building id.
final buildingProvider = FutureProvider.family<Building, String>(
  (ref, id) => ref.watch(buildingRepositoryProvider).getBuilding(id),
);

// ── Units of a building ──────────────────────────────────────────────────--

/// Loads and mutates the units of one building, exposing [AsyncValue]. Keyed
/// by building id via [family].
class BuildingUnitsController
    extends FamilyAsyncNotifier<List<Unit>, String> {
  @override
  Future<List<Unit>> build(String buildingId) =>
      _repo.listUnits(buildingId);

  UnitRepository get _repo => ref.read(unitRepositoryProvider);

  /// Re-fetches this building's units into [state].
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.listUnits(arg));
  }

  /// Creates a single unit under this building, then refreshes.
  Future<Unit> create({
    required String label,
    UnitType? type,
    double? rent,
    List<String>? amenities,
    UnitStatus? status,
    DateTime? availableFrom,
  }) async {
    final unit = await _repo.createUnit(
      arg,
      label: label,
      type: type,
      rent: rent,
      amenities: amenities,
      status: status,
      availableFrom: availableFrom,
    );
    await refresh();
    return unit;
  }

  /// Bulk-generates units under this building, then refreshes. Returns the
  /// newly inserted units.
  Future<List<Unit>> generate({
    required int floors,
    required int perFloor,
    required UnitScheme scheme,
    List<String>? custom,
    List<String>? removed,
  }) async {
    final units = await _repo.generateUnits(
      arg,
      floors: floors,
      perFloor: perFloor,
      scheme: scheme,
      custom: custom,
      removed: removed,
    );
    await refresh();
    return units;
  }

  /// Partially updates a unit in this building, then refreshes.
  Future<Unit> updateUnit(
    String unitId, {
    String? label,
    UnitType? type,
    double? rent,
    List<String>? amenities,
    UnitStatus? status,
    DateTime? availableFrom,
  }) async {
    final unit = await _repo.updateUnit(
      unitId,
      label: label,
      type: type,
      rent: rent,
      amenities: amenities,
      status: status,
      availableFrom: availableFrom,
    );
    await refresh();
    return unit;
  }

  /// Deletes a unit in this building, then refreshes.
  Future<void> delete(String unitId) async {
    await _repo.deleteUnit(unitId);
    await refresh();
  }
}

/// Units of a building, keyed by building id.
final buildingUnitsProvider = AsyncNotifierProvider.family<
    BuildingUnitsController, List<Unit>, String>(
  BuildingUnitsController.new,
);

/// One unit by id — `GET /units/{id}`. Keyed by unit id.
final unitProvider = FutureProvider.family<Unit, String>(
  (ref, id) => ref.watch(unitRepositoryProvider).getUnit(id),
);

/// Loads and mutates a single unit (the unit-detail screen, T-013), exposing
/// [AsyncValue]. Keyed by unit id via [family].
///
/// [build] fetches `GET /units/{id}`. [update] PATCHes the unit and replaces
/// [state] with the server's response (the source of truth) so edits to rent /
/// status / type / amenities persist and re-render in place without a separate
/// re-fetch.
class UnitDetailController extends FamilyAsyncNotifier<Unit, String> {
  @override
  Future<Unit> build(String unitId) => _repo.getUnit(unitId);

  UnitRepository get _repo => ref.read(unitRepositoryProvider);

  /// Re-fetches this unit into [state].
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getUnit(arg));
  }

  /// Partially updates this unit, then replaces [state] with the returned unit.
  /// Only non-null fields are sent. Returns the updated unit.
  Future<Unit> save({
    String? label,
    UnitType? type,
    double? rent,
    List<String>? amenities,
    UnitStatus? status,
    DateTime? availableFrom,
  }) async {
    final unit = await _repo.updateUnit(
      arg,
      label: label,
      type: type,
      rent: rent,
      amenities: amenities,
      status: status,
      availableFrom: availableFrom,
    );
    state = AsyncValue.data(unit);
    return unit;
  }
}

/// Single-unit detail/edit state, keyed by unit id.
final unitDetailProvider =
    AsyncNotifierProvider.family<UnitDetailController, Unit, String>(
  UnitDetailController.new,
);

// ── Portfolio ────────────────────────────────────────────────────────────--

/// Loads the caller's portfolio summary, exposing [AsyncValue].
class PortfolioController extends AsyncNotifier<PortfolioSummary> {
  @override
  Future<PortfolioSummary> build() => _repo.getPortfolio();

  PortfolioRepository get _repo => ref.read(portfolioRepositoryProvider);

  /// Re-fetches the portfolio summary into [state].
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.getPortfolio);
  }
}

/// App-wide portfolio summary state.
final portfolioProvider =
    AsyncNotifierProvider<PortfolioController, PortfolioSummary>(
  PortfolioController.new,
);
