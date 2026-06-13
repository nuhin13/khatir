import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/providers.dart';
import '../../data/warning_notice_sharer.dart';

/// Builds the widget that renders the generated PDF [bytes]. The process-wide
/// default is the real pdfium-backed [PdfPreview]; widget tests override
/// [WarningNoticeScreen.pdfViewBuilder] to avoid the native renderer.
typedef WarningPdfViewBuilder = Widget Function(Uint8List bytes);

/// Warning notice PDF preview + share screen (EPIC-20 T-006).
///
/// Reached from the issue-warning screen at `/warning/:warningId/notice` after
/// a warning is successfully issued. Generates the notice PDF via the server
/// (`POST /warnings/{id}/notice`), downloads the signed-URL bytes, and shows:
/// * **Top bar** — "Warning Notice PDF" title, back action.
/// * **Privacy disclaimer** — prominent reminder that this is private.
/// * **Preview** — the rendered A4 PDF on a muted backdrop.
/// * **Footer** — primary Download + secondary Share actions.
///
/// States: generating (loading), error (retry), data (preview). Mirrors the
/// DMP PDF screen pattern (EPIC-05 T-008 [DmpPdfScreen]).
///
/// All colors/spacing/radius/fonts come from design tokens. No prototype
/// hex/px is hardcoded.
class WarningNoticeScreen extends ConsumerWidget {
  const WarningNoticeScreen({
    super.key,
    required this.warningId,
    WarningPdfViewBuilder? pdfViewBuilder,
    // ignore: prefer_initializing_formals
  }) : _pdfViewBuilder = pdfViewBuilder;

  /// The id of the issued warning whose notice PDF to generate.
  final String warningId;

  /// Optional override for widget tests (avoids the native pdfium renderer).
  final WarningPdfViewBuilder? _pdfViewBuilder;

  static const String routePath = '/warning/:warningId/notice';
  static const String routeName = 'warningNotice';

  /// Typed path for use in `GoRouter.go` / `GoRouter.push`.
  static String pathFor(String warningId) => '/warning/$warningId/notice';

  /// Process-wide default PDF renderer (the real pdfium-backed [PdfPreview]),
  /// overridable in widget tests so they avoid the native renderer.
  static WarningPdfViewBuilder pdfViewBuilder = _defaultPdfView;

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

  WarningPdfViewBuilder get _renderer => _pdfViewBuilder ?? pdfViewBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pdfAsync = ref.watch(warningNoticePdfProvider(warningId));

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const ValueKey('warningNoticeBack'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _back(context),
        ),
        title: Text(
          l10n.warning_notice_title,
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
                ref.read(warningNoticePdfProvider(warningId).notifier).regenerate(),
          ),
          data: (pdf) => Column(
            children: [
              // Privacy disclaimer strip — always visible above the preview.
              _DisclaimerStrip(l10n: l10n),
              Expanded(
                child: ColoredBox(
                  // Muted "paper-on-grey" backdrop behind the rendered page,
                  // matching the DMP PDF screen's preview surface.
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

  String _fileName(WarningNoticePdf pdf) {
    final ref = pdf.notice.noticeRef.trim();
    return ref.isEmpty
        ? 'warning-notice-$warningId.pdf'
        : 'warning-notice-$ref.pdf';
  }

  Future<void> _download(
    BuildContext context,
    WidgetRef ref,
    WarningNoticePdf pdf,
  ) =>
      _runAction(
        context,
        () => ref
            .read(warningNoticeSharerProvider)
            .download(bytes: pdf.bytes, fileName: _fileName(pdf)),
        ref,
      );

  Future<void> _share(
    BuildContext context,
    WidgetRef ref,
    WarningNoticePdf pdf,
  ) =>
      _runAction(
        context,
        () => ref
            .read(warningNoticeSharerProvider)
            .share(bytes: pdf.bytes, fileName: _fileName(pdf)),
        ref,
      );

  /// Runs a share/download side-effect, surfacing failures as a snackbar so
  /// a missing share target or a cancelled save never crashes the screen.
  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
    WidgetRef ref,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await action();
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.warning_notice_action_failed)),
      );
    }
  }
}

/// A compact privacy reminder strip shown above the PDF preview — reinforces
/// that the notice is private to the landlord–tenant relationship.
class _DisclaimerStrip extends StatelessWidget {
  const _DisclaimerStrip({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: KhatirColors.sageBg,
        border: Border(bottom: BorderSide(color: KhatirColors.sage)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KhatirSpacing.s4,
          vertical: KhatirSpacing.s2,
        ),
        child: Text(
          l10n.warning_private_notice,
          style: AppTextStyles.bodySmall.copyWith(
            color: KhatirColors.sageDk,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
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
              l10n.warning_notice_generating,
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

/// Sticky footer with primary Download + secondary Share actions.
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
                key: const ValueKey('warningNoticeDownload'),
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(l10n.warning_notice_download),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KhatirColors.sage,
                  foregroundColor: KhatirColors.cream,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      vertical: KhatirSpacing.s4),
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
                key: const ValueKey('warningNoticeShare'),
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded, size: 16),
                label: Text(l10n.warning_notice_share),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KhatirColors.sageDk,
                  backgroundColor: KhatirColors.sageBg,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                      vertical: KhatirSpacing.s4),
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

/// Error state with retry, mirroring the DMP PDF screen's error branch.
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
              l10n.warning_notice_error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: KhatirSpacing.s4),
            OutlinedButton(
              key: const ValueKey('warningNoticeRetry'),
              onPressed: onRetry,
              child: Text(l10n.warning_notice_retry),
            ),
          ],
        ),
      ),
    );
  }
}
