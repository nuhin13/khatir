import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:khatir_tokens/khatir_tokens.dart';
import 'package:latlong2/latlong.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Signature for the pluggable reverse-geocoder.
///
/// Given the dropped pin's coordinates, returns a best-effort human-readable
/// address. The default implementation ([coordsAsTextGeocoder]) simply renders
/// the coordinates as text; a real network geocoder can be injected later
/// without touching the widget.
typedef ReverseGeocoder = Future<String> Function(LatLng latLng);

/// Default reverse-geocode stub: renders the coordinates as text.
///
/// Used until a real (network) geocoder is wired in. Kept out-of-class so it
/// can be referenced as a `const` default and unit-tested in isolation.
Future<String> coordsAsTextGeocoder(LatLng latLng) async {
  final lat = latLng.latitude.toStringAsFixed(4);
  final lng = latLng.longitude.toStringAsFixed(4);
  final ns = latLng.latitude >= 0 ? 'N' : 'S';
  final ew = latLng.longitude >= 0 ? 'E' : 'W';
  return '${lat.replaceFirst('-', '')}°$ns, ${lng.replaceFirst('-', '')}°$ew';
}

/// Reusable tap-to-drop-pin map widget backed by OpenStreetMap tiles.
///
/// OSM is free and needs no API key; the required attribution is shown as an
/// overlay. Tapping the map drops a pin and fires [onChanged] with the chosen
/// [LatLng]. When a [reverseGeocode] hook is provided (or the default stub),
/// the resolved address is also passed back via [onAddressResolved] so callers
/// can pre-fill an (editable) address field.
///
/// All colours/spacing/radii come from the shared design tokens — no hardcoded
/// prototype hex/px. Visual parity with the `addBuilding` step-2 map block is
/// achieved with our tokens rather than Google branding.
class KMapPicker extends StatefulWidget {
  const KMapPicker({
    super.key,
    this.initialCenter = const LatLng(23.8103, 90.4125), // Dhaka
    this.initialZoom = 13,
    this.initialPin,
    this.onChanged,
    this.onAddressResolved,
    this.reverseGeocode = coordsAsTextGeocoder,
    this.height = 210,
    this.userAgentPackageName = 'com.khatir.mobile',
  });

  /// Map centre used when no pin is supplied. Defaults to central Dhaka.
  final LatLng initialCenter;

  /// Initial zoom level.
  final double initialZoom;

  /// A pin to render on first build (e.g. when editing an existing address).
  final LatLng? initialPin;

  /// Fired whenever the user drops/moves the pin.
  final ValueChanged<LatLng>? onChanged;

  /// Fired with the best-effort address resolved by [reverseGeocode].
  final ValueChanged<String>? onAddressResolved;

  /// Pluggable reverse-geocoder. Defaults to a coords-as-text stub.
  final ReverseGeocoder reverseGeocode;

  /// Fixed map height (matches the prototype's 210px map block).
  final double height;

  /// User-agent identifier sent to the OSM tile server (be a polite client).
  final String userAgentPackageName;

  @override
  State<KMapPicker> createState() => _KMapPickerState();
}

class _KMapPickerState extends State<KMapPicker> {
  late final MapController _controller = MapController();
  LatLng? _pin;

  @override
  void initState() {
    super.initState();
    _pin = widget.initialPin;
  }

  Future<void> _handleTap(TapPosition _, LatLng latLng) async {
    setState(() => _pin = latLng);
    widget.onChanged?.call(latLng);

    final address = await widget.reverseGeocode(latLng);
    if (!mounted) return;
    widget.onAddressResolved?.call(address);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(KhatirRadius.card);

    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: KhatirColors.card,
          borderRadius: radius,
          boxShadow: AppTheme.softShadow,
        ),
        child: SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  initialCenter: _pin ?? widget.initialCenter,
                  initialZoom: widget.initialZoom,
                  onTap: _handleTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: widget.userAgentPackageName,
                    // Polite client: keep cached tiles around to limit volume.
                    tileProvider: NetworkTileProvider(),
                  ),
                  if (_pin != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _pin!,
                          width: 40,
                          height: 50,
                          alignment: Alignment.topCenter,
                          child: Icon(
                            Icons.location_on,
                            size: 40,
                            color: KhatirColors.rose,
                          ),
                        ),
                      ],
                    ),
                  // Required OpenStreetMap attribution.
                  RichAttributionWidget(
                    alignment: AttributionAlignment.bottomRight,
                    attributions: [
                      TextSourceAttribution(l10n.map_picker_attribution),
                    ],
                  ),
                ],
              ),
              if (_pin == null) _TapHint(label: l10n.map_picker_tap_hint),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Tap to drop pin" prompt shown until the first pin is dropped.
class _TapHint extends StatelessWidget {
  const _TapHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: KhatirColors.card,
            borderRadius: BorderRadius.circular(KhatirRadius.pill),
            boxShadow: AppTheme.softShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KhatirSpacing.s4,
              vertical: KhatirSpacing.s2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app, size: 18, color: KhatirColors.sageDk),
                const SizedBox(width: KhatirSpacing.s2),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: KhatirFonts.title,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: KhatirColors.sageDk,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
