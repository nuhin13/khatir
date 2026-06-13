import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/dmpform_providers.dart';
import '../../data/models/dmp_preview.dart';

/// DMP-form preview (EPIC-05 T-007), mirroring the `dmp` prototype
/// (`proto/screens-landlord2.js` → `reg('dmp')`).
///
/// The landlord reviews the assembled police-form data — with the **NID masked**
/// — before generating the PDF. Composition, top to bottom:
/// * **Top bar** — "DMP form" title, a back action, and a "ready" chip.
/// * **Hero** — a celebratory "all done" heading (the form is assembled).
/// * **Form card** — the DMP header (DMP · CIMS · tenant information) and the
///   labelled field rows (tenant / NID / landlord / address / from / family /
///   occupation), followed by the household table when present.
/// * **Actions** — a primary "Generate PDF" button → the PDF screen (T-008) and
///   a soft "Edit" button → back to the tenant edit flow (EPIC-04).
///
/// States: loading (spinner), error (retry), data. All colors/spacing/radii/
/// fonts come from the design tokens; no prototype hex/px is hardcoded. The full
/// NID is never shown — only the masked value the server returns.
class DmpPreviewScreen extends ConsumerWidget {
  const DmpPreviewScreen({
    super.key,
    required this.tenantId,
    this.onGenerate,
    this.onEdit,
  });

  /// The tenant whose assembled DMP form is previewed.
  final String tenantId;

  /// Generate-PDF action override (test seam). When null, navigates to the PDF
  /// screen route `/dmpform/{tenantId}/pdf` (registered by T-008).
  final void Function(BuildContext context)? onGenerate;

  /// Edit action override (test seam). When null, pops back to the tenant edit
  /// flow (EPIC-04); falls back to the landlord home when there is nothing to
  /// pop (e.g. a deep link straight onto the preview).
  final void Function(BuildContext context)? onEdit;

  /// `/dmpform/{tenantId}` — the convergent success destination of the
  /// add-tenant flow. The route name is unchanged from the EPIC-04 placeholder
  /// so existing callers (the save action, the router) keep working.
  static const String routeName = 'dmpForm';

  /// Route the PDF screen (T-008) is registered under: `/dmpform/{id}/pdf`.
  static String pdfPathFor(String tenantId) => '/dmpform/$tenantId/pdf';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final previewAsync = ref.watch(dmpPreviewProvider(tenantId));

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.dmp_title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (previewAsync.hasValue)
            Padding(
              padding: const EdgeInsets.only(right: KhatirSpacing.s4),
              child: _ReadyChip(label: l10n.dmp_ready),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: previewAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            l10n: l10n,
            onRetry: () =>
                ref.read(dmpPreviewProvider(tenantId).notifier).refresh(),
          ),
          data: (preview) => _PreviewBody(
            preview: preview,
            onGenerate: () => _generate(context),
            onEdit: () => _edit(context),
          ),
        ),
      ),
    );
  }

  void _generate(BuildContext context) {
    final override = onGenerate;
    if (override != null) {
      override(context);
      return;
    }
    GoRouter.of(context).push(pdfPathFor(tenantId));
  }

  void _edit(BuildContext context) {
    final override = onEdit;
    if (override != null) {
      override(context);
      return;
    }
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/landlord/home');
    }
  }
}

/// Small "ready" pill shown in the top bar.
class _ReadyChip extends StatelessWidget {
  const _ReadyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s3,
        vertical: KhatirSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 14, color: KhatirColors.sageDk),
          const SizedBox(width: KhatirSpacing.s1),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: KhatirColors.sageDk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The populated preview content: hero + form card + actions.
class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.preview,
    required this.onGenerate,
    required this.onEdit,
  });

  final DmpPreview preview;
  final VoidCallback onGenerate;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final rows = <_FieldRow>[
      _FieldRow(label: l10n.dmp_field_tenant, value: preview.tenantName),
      _FieldRow(label: l10n.dmp_field_nid, value: preview.nidNumber),
      _FieldRow(label: l10n.dmp_field_landlord, value: preview.landlordName),
      _FieldRow(label: l10n.dmp_field_address, value: preview.buildingAddress),
      _FieldRow(label: l10n.dmp_field_present, value: preview.presentAddress),
      _FieldRow(
        label: l10n.dmp_field_permanent,
        value: preview.permanentAddress,
      ),
      _FieldRow(label: l10n.dmp_field_dob, value: preview.dob),
      _FieldRow(label: l10n.dmp_field_phone, value: preview.landlordPhone),
    ].where((r) => r.value.trim().isNotEmpty).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s4,
        KhatirSpacing.s2,
        KhatirSpacing.s4,
        KhatirSpacing.s6,
      ),
      children: [
        _Hero(title: l10n.dmp_hero_title, subtitle: l10n.dmp_hero_sub),
        const SizedBox(height: KhatirSpacing.s2),
        _FormCard(
          rows: rows,
          familyMembers: preview.familyMembers,
          l10n: l10n,
        ),
        const SizedBox(height: KhatirSpacing.s5),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const ValueKey('dmpGenerate'),
            onPressed: onGenerate,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(l10n.dmp_generate),
            style: ElevatedButton.styleFrom(
              backgroundColor: KhatirColors.sage,
              foregroundColor: KhatirColors.cream,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
              textStyle: AppTextStyles.labelLarge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KhatirRadius.button),
              ),
            ),
          ),
        ),
        const SizedBox(height: KhatirSpacing.s3),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('dmpEdit'),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text(l10n.dmp_edit),
            style: OutlinedButton.styleFrom(
              foregroundColor: KhatirColors.sageDk,
              backgroundColor: KhatirColors.sageBg,
              side: BorderSide.none,
              padding:
                  const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
              textStyle: AppTextStyles.labelLarge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KhatirRadius.button),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Celebratory "all done" hero above the form card.
class _Hero extends StatelessWidget {
  const _Hero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: KhatirSpacing.s4),
        const Text('🎉', style: TextStyle(fontSize: 44)),
        const SizedBox(height: KhatirSpacing.s2),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: KhatirSpacing.s1),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.mutedDk),
        ),
        const SizedBox(height: KhatirSpacing.s4),
      ],
    );
  }
}

/// The white form card: DMP header + field rows + household table.
class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.rows,
    required this.familyMembers,
    required this.l10n,
  });

  final List<_FieldRow> rows;
  final List<DmpFamilyMember> familyMembers;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KhatirSpacing.s5,
          vertical: KhatirSpacing.s5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // DMP header block.
            Column(
              children: [
                const Text('🏛️', style: TextStyle(fontSize: 22)),
                const SizedBox(height: KhatirSpacing.s1),
                Text(
                  l10n.dmp_org,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: KhatirSpacing.s1),
                Text(
                  l10n.dmp_org_sub,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: KhatirColors.mutedDk, letterSpacing: 1),
                ),
                const SizedBox(height: KhatirSpacing.s3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KhatirSpacing.s3,
                    vertical: KhatirSpacing.s1,
                  ),
                  decoration: BoxDecoration(
                    color: KhatirColors.roseBg,
                    borderRadius: BorderRadius.circular(KhatirRadius.chip),
                  ),
                  child: Text(
                    l10n.dmp_org_badge,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: KhatirColors.roseDk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
              child: Divider(height: 1, color: KhatirColors.line),
            ),
            // Field rows.
            for (var i = 0; i < rows.length; i++) ...[
              _FieldRowTile(row: rows[i]),
              if (i < rows.length - 1)
                const Divider(height: 1, color: KhatirColors.line),
            ],
            if (familyMembers.isNotEmpty) ...[
              const SizedBox(height: KhatirSpacing.s4),
              Text(
                l10n.dmp_field_family,
                style: AppTextStyles.bodySmall.copyWith(
                  color: KhatirColors.mutedDk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: KhatirSpacing.s2),
              for (final m in familyMembers)
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: KhatirSpacing.s1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.name,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        m.relation,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: KhatirColors.mutedDk),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One label/value pair on the form.
class _FieldRow {
  const _FieldRow({required this.label, required this.value});

  final String label;
  final String value;
}

/// Renders a single [_FieldRow] as a label column + value.
class _FieldRowTile extends StatelessWidget {
  const _FieldRowTile({required this.row});

  final _FieldRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              row.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: KhatirColors.mutedDk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.value,
              style:
                  AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error state with a retry, mirroring the other data-screen error branches.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.l10n, required this.onRetry});

  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 40, color: KhatirColors.danger),
            const SizedBox(height: KhatirSpacing.s3),
            Text(
              l10n.dmp_error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: KhatirSpacing.s4),
            OutlinedButton(
              key: const ValueKey('dmpRetry'),
              onPressed: onRetry,
              child: Text(l10n.dmp_retry),
            ),
          ],
        ),
      ),
    );
  }
}
