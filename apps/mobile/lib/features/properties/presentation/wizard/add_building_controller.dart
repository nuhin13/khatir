import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/models/property_enums.dart';

/// Immutable snapshot of the entire 4-step add-building wizard.
///
/// One state object holds every field across all four steps (mirroring the
/// prototype's single shared-state approach in `screens-landlord.js`):
/// * Step 1 — [name], [area].
/// * Step 2 — [address], [lat]/[lng] (the optional map pin).
/// * Steps 3–4 (T-011) — the units builder config: [floors], [perFloor],
///   [scheme], [customLabels], [removedLabels].
///
/// Persisting everything in one place means the user can move back and forth
/// between steps without losing input. This task (T-010) only drives steps 1–2;
/// the units fields are carried here so T-011 can extend without reshaping the
/// state.
class AddBuildingState {
  const AddBuildingState({
    this.step = 1,
    this.name = '',
    this.area,
    this.address = '',
    this.lat,
    this.lng,
    this.addressAutoFilled = false,
    this.floors = 3,
    this.perFloor = 2,
    this.scheme = UnitScheme.letter,
    this.customLabels = const [],
    this.removedLabels = const {},
  });

  /// 1-based current step (1..4).
  final int step;

  // ── Step 1 ────────────────────────────────────────────────────────────────
  /// Building name (required to leave step 1).
  final String name;

  /// Selected area (required to leave step 1).
  final Area? area;

  // ── Step 2 ────────────────────────────────────────────────────────────────
  /// Full address (required to leave step 2). Always editable even when the map
  /// pin auto-fills it.
  final String address;

  /// Latitude of the optional map pin.
  final double? lat;

  /// Longitude of the optional map pin.
  final double? lng;

  /// Whether [address] was last filled from the map (drives the "(auto)" hint).
  final bool addressAutoFilled;

  // ── Steps 3–4 (units; carried for T-011) ────────────────────────────────--
  /// Number of floors for bulk unit generation.
  final int floors;

  /// Units per floor for bulk unit generation.
  final int perFloor;

  /// Numbering scheme for generated unit labels.
  final UnitScheme scheme;

  /// Extra custom unit labels added by the user.
  final List<String> customLabels;

  /// Generated labels the user removed.
  final Set<String> removedLabels;

  /// True when a map pin has been dropped.
  bool get hasPin => lat != null && lng != null;

  /// Step-1 is complete when a non-blank name and an area are set.
  bool get step1Valid => name.trim().isNotEmpty && area != null;

  /// Step-2 is complete when a non-blank address is set (the pin is optional).
  bool get step2Valid => address.trim().isNotEmpty;

  AddBuildingState copyWith({
    int? step,
    String? name,
    Area? area,
    String? address,
    double? lat,
    double? lng,
    bool? addressAutoFilled,
    int? floors,
    int? perFloor,
    UnitScheme? scheme,
    List<String>? customLabels,
    Set<String>? removedLabels,
  }) {
    return AddBuildingState(
      step: step ?? this.step,
      name: name ?? this.name,
      area: area ?? this.area,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      addressAutoFilled: addressAutoFilled ?? this.addressAutoFilled,
      floors: floors ?? this.floors,
      perFloor: perFloor ?? this.perFloor,
      scheme: scheme ?? this.scheme,
      customLabels: customLabels ?? this.customLabels,
      removedLabels: removedLabels ?? this.removedLabels,
    );
  }
}

/// Drives the add-building wizard's shared state. A single [Notifier] owns all
/// fields so navigating between steps never loses input. The host screen reads
/// [AddBuildingState.step] to pick which step view to render and calls [next]/
/// [back] (gated by the per-step validity getters) to move.
class AddBuildingController extends AutoDisposeNotifier<AddBuildingState> {
  @override
  AddBuildingState build() => const AddBuildingState();

  // ── Step 1 mutations ───────────────────────────────────────────────────--
  void setName(String name) => state = state.copyWith(name: name);

  void setArea(Area area) => state = state.copyWith(area: area);

  // ── Step 2 mutations ───────────────────────────────────────────────────--
  /// User-typed address edit. Clears the auto-filled flag so the "(auto)" hint
  /// disappears once the field is hand-edited.
  void setAddress(String address) =>
      state = state.copyWith(address: address, addressAutoFilled: false);

  /// Drops/moves the map pin. Keeps the existing address (a separate
  /// [fillAddressFromMap] call applies the resolved address) so a pin move
  /// never silently overwrites a hand-typed address.
  void setPin(double lat, double lng) =>
      state = state.copyWith(lat: lat, lng: lng);

  /// Applies the reverse-geocoded address from the map and marks it auto-filled.
  /// The field stays editable; [setAddress] reverts the flag on edit.
  void fillAddressFromMap(String address) =>
      state = state.copyWith(address: address, addressAutoFilled: true);

  /// Clears the dropped pin (the "reset" affordance). Leaves the address text as
  /// the user may still want it.
  void clearPin() => state = AddBuildingState(
        step: state.step,
        name: state.name,
        area: state.area,
        address: state.address,
        addressAutoFilled: false,
        floors: state.floors,
        perFloor: state.perFloor,
        scheme: state.scheme,
        customLabels: state.customLabels,
        removedLabels: state.removedLabels,
      );

  // ── Navigation ─────────────────────────────────────────────────────────--
  /// Advances to the next step (capped at 4). Callers gate on the per-step
  /// validity getters before calling this.
  void next() {
    if (state.step < 4) state = state.copyWith(step: state.step + 1);
  }

  /// Returns to the previous step (floored at 1).
  void back() {
    if (state.step > 1) state = state.copyWith(step: state.step - 1);
  }
}

/// App-wide add-building wizard state. Auto-disposed so each time the wizard is
/// opened it starts clean (no stale name/area/address from a prior session).
final addBuildingControllerProvider =
    AutoDisposeNotifierProvider<AddBuildingController, AddBuildingState>(
  AddBuildingController.new,
);
