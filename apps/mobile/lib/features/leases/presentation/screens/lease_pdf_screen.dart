import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/lease_document_providers.dart';
import '../../data/lease_document_repository.dart';

/// Builds the widget that renders the lease PDF [bytes]. Defaults to the
/// real `printing` [PdfPreview] (pdfium); widget tests override
/// [LeasePdfScreen.pdfViewBuilder] with a lightweight stub.
typedef LeasePdfViewBuilder = Widget Function(Uint8List bytes);

/// Lease PDF preview + share screen (EPIC-18 T-008).
///
/// Route: `/lease/:id/pdf`
///
/// Reuses the EPIC-05 DMP PDF preview pattern:
/// * Fetches PDF bytes via `POST /leases/{id}/document/pdf` using
///   [LeaseDocumentRepository.getDocumentPdfBytes].
/// * Renders the bytes with `printing`'s [PdfPreview].
/// * Shows a non-dismissible disclaimer banner above the footer.
/// * Sticky footer: **Download** (sage) + **Share** (sageBg).
///
/// All colours/spacing/radii come from design tokens; no hex/px hardcoded.
class LeasePdfScreen extends ConsumerWidget {
  const LeasePdfScreen({
    super.key,
    required this.leaseId,
    LeasePdfViewBuilder? pdfViewBuilder,
    // ignore: prefer_initializing_formals
  }) : _pdfViewBuilder = pdfViewBuilder;

  /// The lease whose document PDF is previewed and shared.
  final String leaseId;

  /// Optional test-seam override for a single instance.
  final LeasePdfViewBuilder? _pdfViewBuilder;

  static const String routeName = 'leasePdf';
  static String pathFor(String leaseId) => '/lease/$leaseId/pdf';

  /// Process-wide default PDF renderer (real pdfium [PdfPreview]).
  /// Tests override this field directly to avoid the native renderer.
  static LeasePdfViewBuilder pdfViewBuilder = _defaultPdfView;

  static Widget _defaultPdfView(Uint8List bytes) => PdfPreview(
        build: (_) async => bytes,
        useActions: false,
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        loadingWidget: const Center(child: CircularProgressIndicator()),
      );

  LeasePdfViewBuilder get _renderer => _pdfViewBuilder ?? pdfViewBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pdfAsync = ref.watch(_leasePdfProvider(leaseId));

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        key: const ValueKey('leasePdfAppBar'),
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const ValueKey('leasePdfBack'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _back(context),
        ),
        title: Text(
          l10n.lease_pdf_title,
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
                ref.read(_leasePdfProvider(leaseId).notifier).regenerate(),
          ),
          data: (bytes) => Column(
            children: [
              // Non-dismissible disclaimer banner — always visible above the
              // footer so it cannot be missed before sharing/downloading.
              _DisclaimerBanner(l10n: l10n),
              Expanded(
                child: ColoredBox(
                  color: KhatirColors.mutedDk,
                  child: _renderer(bytes),
                ),
              ),
              _ActionsFooter(
                l10n: l10n,
                onDownload: () => _download(context, bytes, l10n),
                onShare: () => _share(context, bytes, l10n),
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

  String _fileName() => 'lease-$leaseId.pdf';

  Future<void> _download(
    BuildContext context,
    Uint8List bytes,
    AppLocalizations l10n,
  ) =>
      _runAction(context, l10n, () async {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                bytes,
                name: _fileName(),
                mimeType: 'application/pdf',
              ),
            ],
          ),
        );
      });

  Future<void> _share(
    BuildContext context,
    Uint8List bytes,
    AppLocalizations l10n,
  ) =>
      _runAction(context, l10n, () async {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                bytes,
                name: _fileName(),
                mimeType: 'application/pdf',
              ),
            ],
            text: l10n.lease_pdf_title,
          ),
        );
      });

  Future<void> _runAction(
    BuildContext context,
    AppLocalizations l10n,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.lease_pdf_action_failed)),
      );
    }
  }
}

// ── PDF provider ──────────────────────────────────────────────────────────────

/// Generates the lease PDF bytes, keyed by lease id.
/// Wraps [LeaseDocumentRepository.getDocumentPdfBytes] in an
/// [AsyncNotifier.family] so the PDF screen can regenerate on retry.
class _LeasePdfController extends FamilyAsyncNotifier<Uint8List, String> {
  @override
  Future<Uint8List> build(String leaseId) =>
      ref.read(leaseDocumentRepositoryProvider).getDocumentPdfBytes(leaseId);

  /// Re-generates the PDF (error-state retry).
  Future<void> regenerate() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () =>
          ref.read(leaseDocumentRepositoryProvider).getDocumentPdfBytes(arg),
    );
  }
}

final _leasePdfProvider =
    AsyncNotifierProvider.family<_LeasePdfController, Uint8List, String>(
  _LeasePdfController.new,
);

// ── Widgets ───────────────────────────────────────────────────────────────────

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

/// Non-dismissible disclaimer banner — legal requirement; always visible.
class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('leasePdfDisclaimer'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s4,
        vertical: KhatirSpacing.s3,
      ),
      color: KhatirColors.butterBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: KhatirColors.butterDk,
            size: 16,
          ),
          const SizedBox(width: KhatirSpacing.s2),
          Expanded(
            child: Text(
              l10n.lease_disclaimer,
              style: AppTextStyles.bodySmall.copyWith(
                color: KhatirColors.butterDk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
            const CircularProgressIndicator(
              key: ValueKey('leasePdfLoading'),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            Text(
              l10n.lease_pdf_generating,
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
            const Icon(
              Icons.error_outline,
              size: 40,
              color: KhatirColors.danger,
            ),
            const SizedBox(height: KhatirSpacing.s3),
            Text(
              l10n.lease_pdf_error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: KhatirSpacing.s4),
            OutlinedButton(
              key: const ValueKey('leasePdfRetry'),
              onPressed: onRetry,
              child: Text(l10n.lease_pdf_retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticky footer: primary Download + soft Share.
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
                key: const ValueKey('leasePdfDownload'),
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(l10n.lease_pdf_download),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KhatirColors.sage,
                  foregroundColor: KhatirColors.cream,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: KhatirSpacing.s4,
                  ),
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
                key: const ValueKey('leasePdfShare'),
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded, size: 16),
                label: Text(l10n.lease_pdf_share),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KhatirColors.sageDk,
                  backgroundColor: KhatirColors.sageBg,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                    vertical: KhatirSpacing.s4,
                  ),
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
