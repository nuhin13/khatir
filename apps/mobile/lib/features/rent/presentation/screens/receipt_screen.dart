import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../../data/receipt_sharer.dart';

/// Typed `extra` payload the router carries into [ReceiptScreen] from the
/// verify-payment flow. The rent detail endpoint surfaces only the request
/// (amount/period/status), so the contextual receipt fields — the tenant name,
/// the unit label, the payment method, the human receipt number, and the signed
/// receipt-PDF URL — ride along here, the same convention the verify screen uses
/// for the submitted proof. All fields are optional; missing values degrade to a
/// neutral dash and a text-only share.
class ReceiptArgs {
  const ReceiptArgs({
    this.tenantName,
    this.unitLabel,
    this.method,
    this.receiptNo,
    this.pdfUrl,
  });

  /// Display name of the tenant the receipt is for.
  final String? tenantName;

  /// Human unit label (e.g. "2C · Karim Manzil").
  final String? unitLabel;

  /// Payment method line (e.g. "bKash · 8GH4K2L9PQ").
  final String? method;

  /// Human receipt number (e.g. "KHT/2026/RC-0512").
  final String? receiptNo;

  /// Absolute, signed receipt-PDF URL (the verify response's `receipt_ref`).
  /// When supplied the screen downloads its bytes so Share/Download act on the
  /// real PDF; when absent the share falls back to a plain-text summary.
  final String? pdfUrl;
}

/// Rent receipt screen (EPIC-07 T-013), reached at `/rent/:id/receipt` after a
/// landlord verifies a payment. It shows the generated receipt summary — the
/// paid amount, tenant, unit, period, method, status and receipt number — and
/// lets the landlord **send it to the tenant** (WhatsApp / system share) or
/// **save the PDF**, reusing the EPIC-05 T-008 PDF share/download seam.
///
/// Per the `receipt` prototype (`proto/screens-landlord2.js` → `reg('receipt')`):
/// a "Receipt ready" hero, a centred receipt card (brand mark, big amount, a
/// dashed divider, the labelled rows and a mono receipt-no footnote), then the
/// two sticky actions. All colours/spacing/radius/fonts come from the design
/// tokens; no prototype hex/px is hardcoded.
///
/// The request is loaded via [rentRequestControllerProvider] (the single source
/// of truth shared with the verify transitions) for the amount/period/status.
/// The contextual fields (tenant, unit, method, receipt no, signed PDF URL) are
/// supplied by the caller via [ReceiptArgs] since the detail endpoint does not
/// surface them yet. When a [ReceiptArgs.pdfUrl] is present its bytes are
/// downloaded so Share/Download act on the real PDF; otherwise a plain-text
/// summary is shared.
///
/// States: **loading** (the request is resolving), **load error** (a retry),
/// **data** (the receipt + actions). A failed share/download surfaces a friendly
/// snackbar so a missing share target / cancelled save never crashes the screen.
class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({
    super.key,
    required this.requestId,
    this.args,
    this.onShared,
    this.onDone,
  });

  /// The settled rent request whose receipt is shown — always supplied (the
  /// screen is launched at `/rent/:id/receipt`). Drives the load.
  final String requestId;

  /// Optional contextual receipt data (tenant/unit/method/receipt no/PDF url).
  final ReceiptArgs? args;

  /// Test seam: invoked instead of the real share when the landlord taps "Send
  /// to tenant". When null (the default, and what the router supplies) the real
  /// share runs.
  final Future<void> Function()? onShared;

  /// Test seam: invoked instead of the real download/navigation when the
  /// landlord taps "PDF · Done". When null the real action runs (download the
  /// PDF if present, then return home).
  final Future<void> Function()? onDone;

  static const String routePath = '/rent/:id/receipt';
  static const String routeName = 'receipt';

  static String pathFor(String id) => '/rent/$id/receipt';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final requestAsync = ref.watch(rentRequestControllerProvider(requestId));

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const ValueKey('receiptBack'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _back(context),
        ),
        title: Text(
          l10n.receipt_title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: requestAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _LoadError(
            l10n: l10n,
            onRetry: () => ref
                .read(rentRequestControllerProvider(requestId).notifier)
                .refresh(),
          ),
          data: (request) => _Body(
            request: request,
            args: args,
            l10n: l10n,
            onShare: () => _share(context, ref, request),
            onDone: () => _done(context, ref, request),
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

  String _fileName(RentRequest request) {
    final no = args?.receiptNo?.trim() ?? '';
    final id = no.isNotEmpty ? no.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-') : requestId;
    return 'rent-receipt-$id.pdf';
  }

  /// Share the receipt with the tenant — the generated PDF when a signed URL is
  /// available, otherwise a plain-text summary.
  Future<void> _share(
    BuildContext context,
    WidgetRef ref,
    RentRequest request,
  ) =>
      _runAction(context, () async {
        if (onShared != null) return onShared!();
        final sharer = ref.read(receiptSharerProvider);
        final url = args?.pdfUrl?.trim() ?? '';
        if (url.isNotEmpty) {
          final bytes = await ref.read(receiptBytesProvider(url).future);
          await sharer.sharePdf(bytes: bytes, fileName: _fileName(request));
        } else {
          final l10n = AppLocalizations.of(context);
          await sharer.shareText(
            text: l10n.receipt_share_text(
              request.amount.round().toString(),
              request.period,
            ),
            subject: l10n.receipt_heading,
          );
        }
      });

  /// Save the receipt PDF (when present), then return to the landlord home — the
  /// "PDF · Done" action that closes the rent loop.
  Future<void> _done(
    BuildContext context,
    WidgetRef ref,
    RentRequest request,
  ) async {
    final router = GoRouter.maybeOf(context);
    await _runAction(context, () async {
      if (onDone != null) return onDone!();
      final url = args?.pdfUrl?.trim() ?? '';
      if (url.isNotEmpty) {
        final bytes = await ref.read(receiptBytesProvider(url).future);
        await ref
            .read(receiptSharerProvider)
            .downloadPdf(bytes: bytes, fileName: _fileName(request));
      }
    });
    if (onDone == null) router?.go('/landlord/home');
  }

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
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.receipt_action_failed)));
    }
  }
}

/// The populated receipt body: the "ready" hero, the receipt card and the two
/// actions, in a scroll view matching the prototype's `scroll`/`pad` layout.
class _Body extends StatelessWidget {
  const _Body({
    required this.request,
    required this.args,
    required this.l10n,
    required this.onShare,
    required this.onDone,
  });

  final RentRequest request;
  final ReceiptArgs? args;
  final AppLocalizations l10n;
  final VoidCallback onShare;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s5,
        KhatirSpacing.s4,
        KhatirSpacing.s5,
        KhatirSpacing.s6,
      ),
      children: [
        _ReadyHero(l10n: l10n),
        const SizedBox(height: KhatirSpacing.s2),
        _ReceiptCard(request: request, args: args, l10n: l10n),
        const SizedBox(height: KhatirSpacing.s5),
        _ShareButton(label: l10n.receipt_share, onPressed: onShare),
        const SizedBox(height: KhatirSpacing.s3),
        _DoneButton(label: l10n.receipt_done, onPressed: onDone),
      ],
    );
  }
}

/// The "Receipt ready!" emoji hero, mirroring the prototype's `emojiHero`.
class _ReadyHero extends StatelessWidget {
  const _ReadyHero({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('🧾', style: TextStyle(fontSize: 44)),
        const SizedBox(height: KhatirSpacing.s2),
        Text(
          l10n.receipt_ready,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: KhatirSpacing.s1),
        Text(
          l10n.receipt_ready_sub,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.mutedDk),
        ),
      ],
    );
  }
}

/// The centred receipt card: the brand heading, the big paid amount, a dashed
/// divider, the labelled rows and a mono receipt-number footnote.
class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.request,
    required this.args,
    required this.l10n,
  });

  final RentRequest request;
  final ReceiptArgs? args;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final dash = l10n.receipt_dash;
    final rows = <(String, String)>[
      (l10n.receipt_tenant, _orDash(args?.tenantName, dash)),
      (l10n.receipt_unit, _orDash(args?.unitLabel, dash)),
      (l10n.receipt_period, _orDash(request.period, dash)),
      (l10n.receipt_method, _orDash(args?.method, dash)),
      (l10n.receipt_status, l10n.receipt_status_paid),
    ];

    return Container(
      key: const ValueKey('receiptCard'),
      padding: const EdgeInsets.all(KhatirSpacing.s5),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        border: Border.all(color: KhatirColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.receipt_heading,
            textAlign: TextAlign.center,
            style:
                AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: KhatirSpacing.s3),
          Text(
            l10n.receipt_amount(request.amount.round().toString()),
            key: const ValueKey('receiptAmount'),
            textAlign: TextAlign.center,
            style: AppTextStyles.displayLarge.copyWith(
              color: KhatirColors.sageDk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: KhatirSpacing.s4),
          const _DashedDivider(),
          const SizedBox(height: KhatirSpacing.s4),
          for (final row in rows) ...[
            _ReceiptRow(label: row.$1, value: row.$2),
            if (row != rows.last) const SizedBox(height: KhatirSpacing.s2),
          ],
          const SizedBox(height: KhatirSpacing.s4),
          Text(
            '${l10n.receipt_no}: ${_orDash(args?.receiptNo, dash)}',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.muted),
          ),
        ],
      ),
    );
  }

  static String _orDash(String? value, String dash) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? dash : v;
  }
}

/// One label/value line on the receipt — muted label on the left, bold value on
/// the right, matching the prototype's `space-between` rows.
class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style:
                AppTextStyles.bodySmall.copyWith(color: KhatirColors.muted),
          ),
        ),
        const SizedBox(width: KhatirSpacing.s3),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// A dashed horizontal rule, the receipt card's tear line.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final count =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: KhatirColors.lineDk),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The primary "Send to tenant" action — a full-width sage pill (WhatsApp /
/// system share).
class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        key: const ValueKey('receiptShare'),
        onPressed: onPressed,
        icon: const Icon(Icons.share_rounded, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: KhatirColors.sage,
          foregroundColor: KhatirColors.cream,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
          textStyle: AppTextStyles.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KhatirRadius.button),
          ),
        ),
      ),
    );
  }
}

/// The secondary "PDF · Done" action — a full-width soft pill that saves the PDF
/// and closes the loop.
class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const ValueKey('receiptDone'),
        onPressed: onPressed,
        icon: const Icon(Icons.download_rounded, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: KhatirColors.sageDk,
          backgroundColor: KhatirColors.sageBg,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
          textStyle: AppTextStyles.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KhatirRadius.button),
          ),
        ),
      ),
    );
  }
}

/// The load-error state: a friendly message and a retry that re-fetches the
/// request behind the receipt.
class _LoadError extends StatelessWidget {
  const _LoadError({required this.l10n, required this.onRetry});

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
                size: 44, color: KhatirColors.danger),
            const SizedBox(height: KhatirSpacing.s3),
            Text(
              l10n.receipt_load_error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: KhatirColors.mutedDk),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            OutlinedButton(
              key: const ValueKey('receiptRetry'),
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: KhatirColors.sageDk,
                side: const BorderSide(color: KhatirColors.sage),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KhatirRadius.button),
                ),
              ),
              child: Text(l10n.receipt_retry),
            ),
          ],
        ),
      ),
    );
  }
}
