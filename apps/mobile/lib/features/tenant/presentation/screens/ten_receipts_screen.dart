import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/tenant_providers.dart';

/// Tenant receipts list screen (EPIC-19 T-009), per the `tenReceipts`
/// prototype (`proto/screens-other.js` → `reg('tenReceipts')`).
///
/// Paginated list of paid periods with receipt download/share. Reuses the
/// [share_plus] dependency from EPIC-07's receipt sharing pattern.
///
/// States: loading / error / empty / data.
class TenReceiptsScreen extends ConsumerWidget {
  const TenReceiptsScreen({super.key});

  static const String routePath = '/tenant/receipts';
  static const String routeName = 'tenantReceipts';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final receiptsAsync = ref.watch(myReceiptsProvider);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.ten_receipts_title, style: AppTextStyles.titleLarge),
      ),
      body: receiptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString(), style: AppTextStyles.bodyMedium),
              const SizedBox(height: KhatirSpacing.s3),
              TextButton(
                onPressed: () => ref.invalidate(myReceiptsProvider),
                child: const Text('পুনরায় চেষ্টা · Retry'),
              ),
            ],
          ),
        ),
        data: (receipts) => receipts.isEmpty
            ? _EmptyBody(l10n: l10n)
            : _ReceiptsList(receipts: receipts, l10n: l10n),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📃', style: TextStyle(fontSize: 48)),
            const SizedBox(height: KhatirSpacing.s4),
            Text(l10n.ten_receipts_empty, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ReceiptsList extends StatelessWidget {
  const _ReceiptsList({required this.receipts, required this.l10n});

  final List<dynamic> receipts;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final paidCount = receipts
        .where((r) => (r.receiptRef as String).isNotEmpty)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KhatirSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card.
          Container(
            padding: const EdgeInsets.all(KhatirSpacing.s4),
            decoration: BoxDecoration(
              color: KhatirColors.sageBg,
              borderRadius: BorderRadius.circular(KhatirRadius.card),
              border: Border.all(color: KhatirColors.line),
            ),
            child: Row(
              children: [
                const Text('📃', style: TextStyle(fontSize: 28)),
                const SizedBox(width: KhatirSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.ten_receipts_summary(paidCount.toString()),
                        style: AppTextStyles.labelLarge,
                      ),
                      Text(
                        'মোট ৳${receipts.fold<double>(0, (sum, r) => sum + (r.amount as double)).toStringAsFixed(0)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: KhatirColors.mutedDk,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: KhatirSpacing.s4),

          // Receipts list.
          Column(
            children: [
              for (int i = 0; i < receipts.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: KhatirSpacing.s2),
                  child: _ReceiptCard(receipt: receipts[i], l10n: l10n),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt, required this.l10n});

  final dynamic receipt;
  final AppLocalizations l10n;

  bool get _isPaid => (receipt.receiptRef as String).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        border: Border.all(color: KhatirColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isPaid ? KhatirColors.sageBg : KhatirColors.butterBg,
              borderRadius: BorderRadius.circular(KhatirRadius.sm),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 18,
              color: _isPaid ? KhatirColors.sageDk : KhatirColors.roseDk,
            ),
          ),
          const SizedBox(width: KhatirSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(receipt.period as String, style: AppTextStyles.labelLarge),
                Text(
                  _isPaid ? l10n.ten_receipts_paid : l10n.ten_receipts_pending,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _isPaid ? KhatirColors.sage : KhatirColors.roseDk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '৳${(receipt.amount as double).toStringAsFixed(0)}',
                style: AppTextStyles.labelLarge,
              ),
              if (_isPaid)
                GestureDetector(
                  onTap: () => _share(receipt.receiptRef as String),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.download_outlined,
                      size: 15,
                      color: KhatirColors.muted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _share(String url) {
    if (url.isEmpty) return;
    // Share the receipt URL; in production this would download first.
    SharePlus.instance.share(ShareParams(text: url));
  }
}
