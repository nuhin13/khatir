import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/tenant_enums.dart';
import '../../data/tenant_providers.dart';

/// Tenant in-app payment screen (EPIC-19 T-007), per the `tenPay` prototype
/// (`proto/screens-other.js` → `reg('tenPay')`).
///
/// Shows amount due, payment instructions (bKash/Nagad number), and three
/// proof submission options: upload screenshot, enter txn ID, or add a note.
/// Submits via the EPIC-07 payment pipeline. Reuses [ImagePicker] from the
/// existing pubspec dependency.
///
/// States: loading / error / empty (no rent due) / data.
class TenPayScreen extends HookConsumerWidget {
  const TenPayScreen({super.key});

  static const String routePath = '/tenant/pay';
  static const String routeName = 'tenantPay';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rentAsync = ref.watch(myRentProvider);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'ভাড়া পরিশোধ · Pay rent',
          style: AppTextStyles.titleLarge,
        ),
      ),
      body: rentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(KhatirSpacing.s6),
            child: Text(e.toString(), style: AppTextStyles.bodyMedium),
          ),
        ),
        data: (rent) => rent == null
            ? _EmptyBody(l10n: l10n)
            : _PayBody(rent: rent, l10n: l10n),
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
            const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: KhatirColors.sage,
            ),
            const SizedBox(height: KhatirSpacing.s4),
            Text(l10n.ten_pay_no_rent, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _PayBody extends HookConsumerWidget {
  const _PayBody({required this.rent, required this.l10n});

  final dynamic rent; // TenantRent
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnController = useTextEditingController();
    final noteController = useTextEditingController();
    final selectedProof = useState<PayProofType?>(null);
    final isSubmitting = useState(false);
    final leaseAsync = ref.watch(myLeaseProvider);

    Future<void> _handlePickImage() async {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        selectedProof.value = PayProofType.screenshot;
        // In production: upload image and get photoRef; stub here.
      }
    }

    Future<void> _submit() async {
      if (isSubmitting.value) return;
      isSubmitting.value = true;
      try {
        final controller = ref.read(
          myRentControllerProvider(rent.id).notifier,
        );
        await controller.submitProof(
          proofType: selectedProof.value ?? PayProofType.note,
          value: txnController.text.isNotEmpty ? txnController.text : null,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.ten_pay_pending)),
          );
          Navigator.of(context).pop();
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KhatirSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount due card.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(KhatirSpacing.s5),
            decoration: BoxDecoration(
              color: KhatirColors.card,
              borderRadius: BorderRadius.circular(KhatirRadius.card),
              border: Border.all(color: KhatirColors.line),
            ),
            child: Column(
              children: [
                Text(
                  '${rent.period}-এর ভাড়া · ${l10n.ten_pay_amount}',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: KhatirSpacing.s1),
                Text(
                  '৳${rent.amountDue.toStringAsFixed(0)}',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: KhatirColors.roseDk,
                    fontWeight: FontWeight.w800,
                    fontSize: 34,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (leaseAsync.valueOrNull?.landlordPhone.isNotEmpty == true)
                  Text(
                    '${leaseAsync.valueOrNull!.landlordName} · bKash ${leaseAsync.valueOrNull!.landlordPhone}',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),

          const SizedBox(height: KhatirSpacing.s4),
          Text(l10n.ten_pay_instructions, style: AppTextStyles.titleMedium),
          const SizedBox(height: KhatirSpacing.s2),

          // Screenshot upload.
          _ProofOption(
            icon: Icons.upload_outlined,
            title: l10n.ten_pay_screenshot,
            subtitle: 'bKash / Nagad payment proof',
            isSelected: selectedProof.value == PayProofType.screenshot,
            bg: KhatirColors.roseBg,
            iconColor: KhatirColors.roseDk,
            borderColor: selectedProof.value == PayProofType.screenshot
                ? KhatirColors.rose
                : KhatirColors.line,
            onTap: _handlePickImage,
          ),

          const SizedBox(height: KhatirSpacing.s2),

          // Txn ID entry.
          _ProofOption(
            icon: Icons.copy_outlined,
            title: l10n.ten_pay_txn_id,
            subtitle: 'e.g. 8GH4K2L9PQ',
            isSelected: selectedProof.value == PayProofType.txnId,
            bg: KhatirColors.sageBg,
            iconColor: KhatirColors.sageDk,
            borderColor: selectedProof.value == PayProofType.txnId
                ? KhatirColors.sage
                : KhatirColors.line,
            onTap: () => selectedProof.value = PayProofType.txnId,
          ),

          if (selectedProof.value == PayProofType.txnId) ...[
            const SizedBox(height: KhatirSpacing.s2),
            TextField(
              controller: txnController,
              decoration: InputDecoration(
                hintText: 'Transaction ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(KhatirRadius.sm),
                  borderSide: const BorderSide(color: KhatirColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(KhatirRadius.sm),
                  borderSide: const BorderSide(color: KhatirColors.line),
                ),
                filled: true,
                fillColor: KhatirColors.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: KhatirSpacing.s4,
                  vertical: KhatirSpacing.s3,
                ),
              ),
            ),
          ],

          const SizedBox(height: KhatirSpacing.s2),

          // Note.
          _ProofOption(
            icon: Icons.edit_outlined,
            title: l10n.ten_pay_note,
            subtitle: 'নগদ দিয়েছি / cash handed over',
            isSelected: selectedProof.value == PayProofType.note,
            bg: KhatirColors.butterBg,
            iconColor: KhatirColors.roseDk,
            borderColor: selectedProof.value == PayProofType.note
                ? KhatirColors.butter
                : KhatirColors.line,
            onTap: () => selectedProof.value = PayProofType.note,
          ),

          if (selectedProof.value == PayProofType.note) ...[
            const SizedBox(height: KhatirSpacing.s2),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'নোট লিখুন',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(KhatirRadius.sm),
                  borderSide: const BorderSide(color: KhatirColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(KhatirRadius.sm),
                  borderSide: const BorderSide(color: KhatirColors.line),
                ),
                filled: true,
                fillColor: KhatirColors.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: KhatirSpacing.s4,
                  vertical: KhatirSpacing.s3,
                ),
              ),
            ),
          ],

          const SizedBox(height: KhatirSpacing.s4),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSubmitting.value ? null : _submit,
              icon: isSubmitting.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined, size: 18),
              label: Text(l10n.ten_pay_submit),
              style: ElevatedButton.styleFrom(
                backgroundColor: KhatirColors.rose,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: KhatirSpacing.s4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KhatirRadius.button),
                ),
                textStyle: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: KhatirSpacing.s2),
          Center(
            child: Text(
              l10n.ten_pay_pending,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: KhatirSpacing.s6),
        ],
      ),
    );
  }
}

class _ProofOption extends StatelessWidget {
  const _ProofOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.bg,
    required this.iconColor,
    required this.borderColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color bg;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(KhatirSpacing.s3),
        decoration: BoxDecoration(
          color: KhatirColors.card,
          borderRadius: BorderRadius.circular(KhatirRadius.card),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(KhatirRadius.sm),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: KhatirSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
