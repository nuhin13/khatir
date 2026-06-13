import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/building.dart';
import '../../data/properties_providers.dart';
import '../screens/portfolio_screen.dart' show PortfolioScreen, areaLabel;
import 'add_building_controller.dart';
import 'wizard_widgets.dart';

/// Wizard step 4 — the review summary and the save that persists the building
/// and its units.
///
/// Shows a read-only card of every wizard field (building, area, address, pin,
/// unit count + label chips). "Save" creates the building (`POST /buildings`)
/// then bulk-generates the units (`POST /buildings/{id}/units/generate`) and,
/// on success, routes to the portfolio with a success toast. The save is kept
/// transactional client-side: if unit generation fails after the building was
/// created, the half-created building is deleted so the user never lands in the
/// portfolio with a unit-less building, and the error is surfaced for a retry.
class Step4Review extends ConsumerStatefulWidget {
  const Step4Review({super.key});

  @override
  ConsumerState<Step4Review> createState() => _Step4ReviewState();
}

class _Step4ReviewState extends ConsumerState<Step4Review> {
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving) return;
    final state = ref.read(addBuildingControllerProvider);
    final area = state.area;
    if (area == null || !state.step3Valid) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final buildings = ref.read(buildingsProvider.notifier);
    final l10n = AppLocalizations.of(context);
    Building? created;
    try {
      created = await buildings.create(
        name: state.name.trim(),
        area: area,
        address: state.address.trim(),
        lat: state.lat,
        lng: state.lng,
      );
      await ref.read(buildingUnitsProvider(created.id).notifier).generate(
            floors: state.floors,
            perFloor: state.perFloor,
            scheme: state.scheme,
            custom: state.customLabels.isEmpty ? null : state.customLabels,
            removed: state.removedLabels.isEmpty
                ? null
                : state.removedLabels.toList(growable: false),
          );
      // Keep the portfolio summary in sync with the new building + units.
      await ref.read(portfolioProvider.notifier).refresh();
    } on ApiException catch (e) {
      // Roll back a building that has no units so we never persist a half state.
      if (created != null) {
        try {
          await buildings.delete(created.id);
        } on ApiException {
          // Best-effort rollback; surface the original failure regardless.
        }
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.wizard_saved)),
      );
    context.go(PortfolioScreen.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(addBuildingControllerProvider);
    final labels = state.unitLabels;
    final area = state.area;
    final firstAddressLine =
        state.address.trim().isEmpty ? '—' : state.address.trim().split('\n').first;

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
            emoji: '✅',
            title: l10n.wizard_step4_hero_title,
            subtitle: l10n.wizard_step4_hero_sub,
          ),
          const SizedBox(height: KhatirSpacing.s3),
          _ReviewCard(
            rows: [
              (l10n.wizard_review_building, state.name.trim().isEmpty ? '—' : state.name.trim()),
              (l10n.wizard_review_area, area == null ? '—' : areaLabel(l10n, area)),
              (l10n.wizard_review_address, firstAddressLine),
              (
                l10n.wizard_review_pin,
                state.hasPin ? '✓ ${l10n.wizard_review_pin_saved}' : '—',
              ),
              (
                l10n.wizard_review_units,
                l10n.wizard_review_units_value(
                  labels.length,
                  state.floors,
                  state.perFloor,
                ),
              ),
            ],
            labels: labels,
          ),
          if (_error != null) ...[
            const SizedBox(height: KhatirSpacing.s3),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: KhatirSpacing.s4),
          if (_saving)
            const _SavingButton()
          else
            WizardPrimaryButton(
              label: l10n.wizard_save,
              showArrow: false,
              onTap: _save,
            ),
        ],
      ),
    );
  }
}

/// The review summary card: a list of label/value rows plus the unit chips.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.rows, required this.labels});

  final List<(String, String)> rows;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s4,
        vertical: KhatirSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        border: Border.all(color: KhatirColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s2 + 1),
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? const Border(
                        bottom: BorderSide(color: KhatirColors.line),
                      )
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      rows[i].$1,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: KhatirColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      style: TextStyle(
                        fontFamily: KhatirFonts.title,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: KhatirColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (labels.isNotEmpty) ...[
            const SizedBox(height: KhatirSpacing.s2 + 2),
            const Divider(color: KhatirColors.line, height: 1),
            const SizedBox(height: KhatirSpacing.s2 + 2),
            Wrap(
              spacing: KhatirSpacing.s2 - 2,
              runSpacing: KhatirSpacing.s2 - 2,
              children: [
                for (final label in labels)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KhatirSpacing.s2 + 1,
                      vertical: KhatirSpacing.s1,
                    ),
                    decoration: BoxDecoration(
                      color: KhatirColors.sageBg,
                      borderRadius: BorderRadius.circular(KhatirRadius.tile - 8),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: KhatirFonts.title,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: KhatirColors.sageDk,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: KhatirSpacing.s2),
          ],
        ],
      ),
    );
  }
}

/// Inline error banner shown when the save fails.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s3),
      decoration: BoxDecoration(
        color: KhatirColors.dangerBg,
        borderRadius: BorderRadius.circular(KhatirRadius.tile),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: KhatirColors.danger),
          const SizedBox(width: KhatirSpacing.s2),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: KhatirColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The save button while a save is in flight: disabled with a spinner.
class _SavingButton extends StatelessWidget {
  const _SavingButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(KhatirRadius.button);
    return Opacity(
      opacity: 0.7,
      child: Material(
        color: KhatirColors.sage,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s6,
            vertical: KhatirSpacing.s4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(KhatirColors.card),
                ),
              ),
              const SizedBox(width: KhatirSpacing.s2),
              Text(
                l10n.wizard_saving,
                style: AppTextStyles.labelLarge.copyWith(
                  color: KhatirColors.card,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
