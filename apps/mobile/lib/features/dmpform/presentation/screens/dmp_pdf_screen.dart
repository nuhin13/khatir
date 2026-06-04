import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/dmp_pdf_sharer.dart';
import '../../data/dmpform_providers.dart';

/// Builds the widget that renders the generated PDF [bytes]. Defaults to the
/// real `printing` [PdfPreview] (pdfium); widget tests override
/// [DmpPdfScreen.pdfViewBuilder] with a lightweight stub so the headless test
/// never touches the native renderer.
typedef PdfViewBuilder = Widget Function(Uint8List bytes);

/// DMP PDF preview + share screen (EPIC-05 T-008), mirroring the `dmpPdf`
/// prototype (`proto/screens-landlord2.js` → `reg('dmpPdf')`).
///
/// This is the payoff of the DMP wedge: it generates the police form
/// (`POST /tenants/{id}/dmpform/pdf`), downloads the signed-URL PDF, renders it
/// on a paper-grey backdrop, and offers **Download** + **Share** (WhatsApp /
/// system) in a sticky footer. Composition, top to bottom:
/// * **Top bar** — "DMP PDF" title, a back action, and an "A4" chip.
/// * **Preview** — the rendered A4 PDF on a muted backdrop (matching the
///   prototype's paper-on-grey look).
/// * **Footer** — primary "Download" + soft "Share" actions.
///
/// States: generating (loading), error (retry), data (preview). Works on the
/// free tier — there is no entitlement gate. All colors/spacing/radii/fonts come
/// from the design tokens; no prototype hex/px is hardcoded.
class DmpPdfScreen extends ConsumerWidget {
  const DmpPdfScreen({
    super.key,
    required this.tenantId,
    PdfViewBuilder? pdfViewBuilder,
    // A public named param can't be an initializing formal for a private
    // field, so assign it explicitly (the field is a test-only seam).
    // ignore: prefer_initializing_formals
  }) : _pdfViewBuilder = pdfViewBuilder;

  /// The tenant whose DMP PDF is generated and previewed.
  final String tenantId;

  /// Optional override of [pdfViewBuilder] for a single instance (tests).
  final PdfViewBuilder? _pdfViewBuilder;

  /// `/dmpform/{tenantId}/pdf` — pushed from the preview screen's "Generate
  /// PDF" action. The route name is unchanged from the EPIC-05 T-007
  /// placeholder so existing callers keep working.
  static const String routeName = 'dmpFormPdf';
  static String pathFor(String tenantId) => '/dmpform/$tenantId/pdf';

  /// Process-wide default PDF renderer (the real pdfium-backed [PdfPreview]),
  /// overridable in widget tests so they avoid the native renderer.
  static PdfViewBuilder pdfViewBuilder = _defaultPdfView;

  static Widget _defaultPdfView(Uint8List bytes) => PdfPreview(
        build: (_) async => bytes,
        // Use our own sticky footer (Download/Share) instead of the package
        // toolbar, and keep the page format fixed (A4) — no format/orientation
        // toggles, no debug overlay.
        useActions: false,
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        loadingWidget: const Center(child: CircularProgressIndicator()),
      );

  PdfViewBuilder get _renderer => _pdfViewBuilder ?? pdfViewBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pdfAsync = ref.watch(dmpPdfProvider(tenantId));

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const ValueKey('dmpPdfBack'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _back(context),
        ),
        title: Text(
          l10n.dmp_pdf_title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: KhatirSpacing.s4),
            child: _A4Chip(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: pdfAsync.when(
          loading: () => _GeneratingState(l10n: l10n),
          error: (_, _) => _ErrorState(
            l10n: l10n,
            onRetry: () =>
                ref.read(dmpPdfProvider(tenantId).notifier).regenerate(),
          ),
          data: (pdf) => Column(
            children: [
              Expanded(
                child: ColoredBox(
                  // Muted "paper-on-grey" backdrop behind the rendered page,
                  // matching the prototype's preview surface.
                  color: KhatirColors.mutedDk,
                  child: _renderer(pdf.bytes),
                ),
              ),
              _ActionsFooter(
                l10n: l10n,
                onDownload: () => _download(context, ref, pdf),
                onShare: () => _share(context, ref, pdf),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _back(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/landlord/home');
    }
  }

  String _fileName(DmpPdf pdf) {
    final id = pdf.result.recordId.trim();
    return id.isEmpty ? 'dmp-form-$tenantId.pdf' : 'dmp-form-$id.pdf';
  }

  Future<void> _download(BuildContext context, WidgetRef ref, DmpPdf pdf) =>
      _runAction(
        context,
        () => ref
            .read(dmpPdfSharerProvider)
            .download(bytes: pdf.bytes, fileName: _fileName(pdf)),
      );

  Future<void> _share(BuildContext context, WidgetRef ref, DmpPdf pdf) =>
      _runAction(
        context,
        () => ref
            .read(dmpPdfSharerProvider)
            .share(bytes: pdf.bytes, fileName: _fileName(pdf)),
      );

  /// Runs a share/download side-effect, surfacing a failure as a snackbar so a
  /// missing share target / cancelled save never crashes the screen.
  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await action();
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.dmp_pdf_action_failed)),
      );
    }
  }
}

/// Small "A4" pill shown in the top bar.
class _A4Chip extends StatelessWidget {
  const _A4Chip();

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
      child: Text(
        'A4',
        style: AppTextStyles.bodySmall.copyWith(
          color: KhatirColors.sageDk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// "Generating…" loading state shown while the PDF is rendered + downloaded.
class _GeneratingState extends StatelessWidget {
  const _GeneratingState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: KhatirSpacing.s4),
            Text(
              l10n.dmp_generating,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: KhatirColors.mutedDk),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticky footer: primary Download + soft Share (WhatsApp/system).
class _ActionsFooter extends StatelessWidget {
  const _ActionsFooter({
    required this.l10n,
    required this.onDownload,
    required this.onShare,
  });

  final AppLocalizations l10n;
  final VoidCallback onDownload;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: KhatirColors.card,
        border: Border(top: BorderSide(color: KhatirColors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KhatirSpacing.s4,
          vertical: KhatirSpacing.s3,
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                key: const ValueKey('dmpPdfDownload'),
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(l10n.dmp_pdf_download),
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
            const SizedBox(width: KhatirSpacing.s3),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('dmpPdfShare'),
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded, size: 16),
                label: Text(l10n.dmp_pdf_share),
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
        ),
      ),
    );
  }
}

/// Error state with a retry, mirroring the preview screen's error branch.
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
              l10n.dmp_pdf_error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: KhatirSpacing.s4),
            OutlinedButton(
              key: const ValueKey('dmpPdfRetry'),
              onPressed: onRetry,
              child: Text(l10n.dmp_retry),
            ),
          ],
        ),
      ),
    );
  }
}
