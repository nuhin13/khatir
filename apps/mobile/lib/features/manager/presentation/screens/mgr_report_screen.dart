import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:khatir_tokens/khatir_tokens.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/manager_providers.dart';
import '../../data/models/manager_models.dart';

/// Manager report screen (EPIC-22 T-009).
///
/// Allows the manager to:
///  1. Select a linked active owner from a dropdown.
///  2. Generate a PDF report for that owner.
///  3. Preview the summary stats (income, expense, net, occupancy, collection).
///  4. Share the PDF.
///
/// Route: `/manager/report`
class MgrReportScreen extends ConsumerStatefulWidget {
  const MgrReportScreen({super.key});

  static const routePath = 'report';
  static const routeName = 'managerReport';

  @override
  ConsumerState<MgrReportScreen> createState() => _MgrReportScreenState();
}

class _MgrReportScreenState extends ConsumerState<MgrReportScreen> {
  String? _selectedOwnerId;
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ownersAsync = ref.watch(managerOwnersProvider);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          l10n.mgr_report_title,
          style: TextStyle(
            color: KhatirColors.ink,
            fontFamily: KhatirFonts.title,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ownersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e.toString(),
            style: TextStyle(color: KhatirColors.danger),
          ),
        ),
        data: (owners) {
          // Only active owners can have reports generated
          final active = owners.where((o) => o.isActive).toList();
          if (active.isEmpty) {
            return _NoOwners(l10n: l10n);
          }
          // Ensure selected id is still valid
          if (_selectedOwnerId != null &&
              !active.any((o) => o.id == _selectedOwnerId)) {
            _selectedOwnerId = null;
          }
          return _ReportBody(
            activeOwners: active,
            selectedOwnerId: _selectedOwnerId,
            onOwnerChanged: (id) => setState(() => _selectedOwnerId = id),
            generating: _generating,
            onGenerate: _selectedOwnerId == null
                ? null
                : () => _generate(l10n),
            l10n: l10n,
          );
        },
      ),
    );
  }

  Future<void> _generate(AppLocalizations l10n) async {
    if (_selectedOwnerId == null) return;
    setState(() => _generating = true);
    try {
      await ref
          .read(ownerReportProvider(_selectedOwnerId!).notifier)
          .generateReport();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mgr_report_pdf_ready),
            backgroundColor: KhatirColors.sage,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mgr_report_generate_error),
            backgroundColor: KhatirColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}

// ── Report body ─────────────────────────────────────────────────────────────

class _ReportBody extends ConsumerWidget {
  const _ReportBody({
    required this.activeOwners,
    required this.selectedOwnerId,
    required this.onOwnerChanged,
    required this.generating,
    required this.onGenerate,
    required this.l10n,
  });

  final List<LinkedOwner> activeOwners;
  final String? selectedOwnerId;
  final ValueChanged<String?> onOwnerChanged;
  final bool generating;
  final VoidCallback? onGenerate;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = selectedOwnerId != null
        ? ref.watch(ownerReportProvider(selectedOwnerId!))
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Owner selector
          Text(
            l10n.mgr_report_owner,
            style: TextStyle(
              color: KhatirColors.ink,
              fontFamily: KhatirFonts.body,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: KhatirSpacing.s2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: KhatirSpacing.s3),
            decoration: BoxDecoration(
              color: KhatirColors.card,
              borderRadius: BorderRadius.circular(KhatirRadius.md),
              border: Border.all(color: KhatirColors.line),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text(
                  l10n.mgr_report_owner,
                  style: TextStyle(
                    fontFamily: KhatirFonts.body,
                    color: KhatirColors.muted,
                  ),
                ),
                value: selectedOwnerId,
                items: activeOwners
                    .map(
                      (o) => DropdownMenuItem(
                        value: o.id,
                        child: Text(
                          '${o.ownerName} · ${o.ownerPhone}',
                          style: TextStyle(
                            fontFamily: KhatirFonts.body,
                            color: KhatirColors.ink,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onOwnerChanged,
              ),
            ),
          ),

          const SizedBox(height: KhatirSpacing.s5),

          // Report summary (shown when data is loaded)
          if (reportAsync != null) ...[
            reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                e.toString(),
                style: TextStyle(color: KhatirColors.danger),
              ),
              data: (report) => _ReportSummary(report: report, l10n: l10n),
            ),
            const SizedBox(height: KhatirSpacing.s4),
          ],

          // Generate button
          FilledButton.icon(
            onPressed: generating ? null : onGenerate,
            icon: generating
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(
              generating ? l10n.mgr_report_generating : l10n.mgr_report_generate,
              style: TextStyle(
                fontFamily: KhatirFonts.body,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: KhatirColors.sage,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KhatirRadius.button),
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: KhatirSpacing.s3),
            ),
          ),

          // Share button (only when PDF URL is available)
          if (reportAsync?.valueOrNull?.pdfUrl != null) ...[
            const SizedBox(height: KhatirSpacing.s3),
            OutlinedButton.icon(
              onPressed: () {
                final url = reportAsync!.valueOrNull!.pdfUrl!;
                SharePlus.instance.share(ShareParams(text: url));
              },
              icon: const Icon(Icons.share),
              label: Text(
                l10n.mgr_report_share,
                style: TextStyle(
                  fontFamily: KhatirFonts.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: KhatirColors.sage,
                side: BorderSide(color: KhatirColors.sage),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KhatirRadius.button),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: KhatirSpacing.s3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Report summary card ─────────────────────────────────────────────────────

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({required this.report, required this.l10n});

  final OwnerReport report;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en');
    final pct = NumberFormat.percentPattern();

    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        border: Border.all(color: KhatirColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.ownerName,
            style: TextStyle(
              color: KhatirColors.ink,
              fontFamily: KhatirFonts.title,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: KhatirSpacing.s3),
          _Row(label: l10n.mgr_report_income,
              value: l10n.mgr_report_currency(fmt.format(report.totalIncome))),
          _Row(label: l10n.mgr_report_expense,
              value: l10n.mgr_report_currency(fmt.format(report.totalExpense))),
          _Row(
            label: l10n.mgr_report_net,
            value: l10n.mgr_report_currency(fmt.format(report.net)),
            accent: report.net >= 0 ? KhatirColors.sage : KhatirColors.danger,
          ),
          Divider(color: KhatirColors.line, height: KhatirSpacing.s4),
          _Row(
            label: l10n.mgr_report_occupancy,
            value: '${report.occupiedUnits}/${report.totalUnits}',
          ),
          _Row(
            label: l10n.mgr_report_collection,
            value: pct.format(report.collectionRate),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: KhatirColors.ink2,
              fontFamily: KhatirFonts.body,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: accent ?? KhatirColors.ink,
              fontFamily: KhatirFonts.title,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── No owners ───────────────────────────────────────────────────────────────

class _NoOwners extends StatelessWidget {
  const _NoOwners({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 64, color: KhatirColors.muted),
            const SizedBox(height: KhatirSpacing.s4),
            Text(
              l10n.mgr_report_no_owners,
              style: TextStyle(
                color: KhatirColors.ink,
                fontFamily: KhatirFonts.title,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
