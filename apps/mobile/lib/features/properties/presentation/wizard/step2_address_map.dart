import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/k_map_picker.dart';
import '../../../../l10n/app_localizations.dart';
import 'add_building_controller.dart';
import 'wizard_widgets.dart';

/// Wizard step 2 — optional map pin + full address (required).
///
/// "Pick on map" reveals a [KMapPicker]; tapping the map drops a pin, sets
/// lat/lng on the wizard state and auto-fills the address (shown with an
/// "(auto)" hint). The address stays fully editable; hand-editing it clears the
/// auto-filled flag. Advancing requires a non-blank address — the pin itself is
/// optional.
class Step2AddressMap extends ConsumerStatefulWidget {
  const Step2AddressMap({super.key, required this.onNext});

  /// Called when the step is valid and the user advances.
  final VoidCallback onNext;

  @override
  ConsumerState<Step2AddressMap> createState() => _Step2AddressMapState();
}

class _Step2AddressMapState extends ConsumerState<Step2AddressMap> {
  late final TextEditingController _address;
  bool _mapOpen = false;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _address = TextEditingController(
      text: ref.read(addBuildingControllerProvider).address,
    );
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    final controller = ref.read(addBuildingControllerProvider.notifier);
    controller.setAddress(_address.text);
    if (ref.read(addBuildingControllerProvider).address.trim().isEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(addBuildingControllerProvider);
    final controller = ref.read(addBuildingControllerProvider.notifier);

    final addressError = _showErrors && _address.text.trim().isEmpty
        ? l10n.wizard_err_address
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s5,
        0,
        KhatirSpacing.s5,
        KhatirSpacing.s6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WizardHero(
            emoji: '📍',
            title: l10n.wizard_step2_hero_title,
            subtitle: l10n.wizard_step2_hero_sub,
          ),
          const SizedBox(height: KhatirSpacing.s3),
          WizardSoftButton(
            label: l10n.wizard_pick_on_map,
            icon: Icons.map_outlined,
            onTap: () => setState(() => _mapOpen = !_mapOpen),
          ),
          if (_mapOpen) ...[
            const SizedBox(height: KhatirSpacing.s3),
            KMapPicker(
              key: const ValueKey('wizard_map'),
              initialPin: state.hasPin
                  ? LatLng(state.lat!, state.lng!)
                  : null,
              onChanged: (latLng) =>
                  controller.setPin(latLng.latitude, latLng.longitude),
              onAddressResolved: (address) {
                controller.fillAddressFromMap(address);
                _address.text = address;
                if (_showErrors) setState(() {});
              },
            ),
          ],
          if (state.hasPin) ...[
            const SizedBox(height: KhatirSpacing.s3),
            _PinConfirmation(
              lat: state.lat!,
              lng: state.lng!,
              onReset: () {
                controller.clearPin();
                setState(() {});
              },
            ),
          ],
          const SizedBox(height: KhatirSpacing.s3),
          WizardField(
            label: state.addressAutoFilled
                ? '${l10n.building_address} ${l10n.building_address_auto}'
                : l10n.building_address,
            required: true,
            errorText: addressError,
            child: TextField(
              controller: _address,
              minLines: 3,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              style: AppTextStyles.bodyLarge,
              onChanged: (v) {
                controller.setAddress(v);
                if (_showErrors) setState(() {});
              },
              decoration: wizardInputDecoration(l10n.building_address_hint),
            ),
          ),
          const SizedBox(height: KhatirSpacing.s4),
          WizardPrimaryButton(
            label: l10n.wizard_next_units,
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}

/// Confirmation card shown once a pin is dropped: a check line plus the picked
/// coordinates and a reset affordance. Mirrors the prototype's sage-bg rowcard.
class _PinConfirmation extends StatelessWidget {
  const _PinConfirmation({
    required this.lat,
    required this.lng,
    required this.onReset,
  });

  final double lat;
  final double lng;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final coords =
        '${lat.toStringAsFixed(4)}°N, ${lng.toStringAsFixed(4)}°E';
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s3 + 2),
      decoration: BoxDecoration(
        color: KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_outlined,
              size: 18, color: KhatirColors.sageDk),
          const SizedBox(width: KhatirSpacing.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✓ ${l10n.wizard_map_filled}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: KhatirColors.sageDk,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  coords,
                  style: TextStyle(
                    fontFamily: KhatirFonts.mono,
                    fontSize: 11,
                    color: KhatirColors.mutedDk,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onReset,
            child: Text(
              l10n.wizard_reset_pin,
              style: AppTextStyles.bodySmall.copyWith(
                color: KhatirColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
