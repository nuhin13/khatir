import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/tenant_enums.dart';
import '../../data/tenant_providers.dart';

/// Tenant record / rating entry screen (EPIC-19 T-010), per the `tenRecord`
/// prototype (`proto/screens-other.js` → `reg('tenRecord')`).
///
/// STRICTLY PRIVATE — the tenant's private good-tenant record:
///   - Star rating (1–5)
///   - Private notes text field
///   - Consent toggle ("share with next landlord")
///   - Stat cards (on-time months, completed leases, avg rating, disputes)
///
/// This data is NEVER public; consent-gated for any sharing with landlords.
/// Feeds EPIC-21 mutual reviews.
///
/// States: loading / error / empty (first-time) / data.
class TenRecordScreen extends HookConsumerWidget {
  const TenRecordScreen({super.key});

  static const String routePath = '/tenant/record';
  static const String routeName = 'tenantRecord';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recordAsync = ref.watch(myRecordControllerProvider);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('আমার রেকর্ড · My record', style: AppTextStyles.titleLarge),
      ),
      body: recordAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(KhatirSpacing.s6),
            child: Text(e.toString(), style: AppTextStyles.bodyMedium),
          ),
        ),
        data: (record) => _RecordForm(record: record, l10n: l10n),
      ),
    );
  }
}

class _RecordForm extends HookConsumerWidget {
  const _RecordForm({required this.record, required this.l10n});

  final dynamic record; // TenantRecord?
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesController = useTextEditingController(
      text: record?.notes as String? ?? '',
    );
    final rating = useState<int>((record?.rating as int?) ?? 0);
    final consent =
        useState<bool>((record?.consent as RecordConsent?) == RecordConsent.shared);
    final isSaving = useState(false);

    Future<void> _save() async {
      if (isSaving.value) return;
      isSaving.value = true;
      try {
        final controller = ref.read(myRecordControllerProvider.notifier);
        await controller.save(
          rating: rating.value,
          notes: notesController.text.trim(),
          consent: consent.value ? RecordConsent.shared : RecordConsent.private,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('সংরক্ষণ হয়েছে · Saved')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        isSaving.value = false;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KhatirSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero gradient card.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(KhatirSpacing.s5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [KhatirColors.sage, KhatirColors.sageDk],
              ),
              borderRadius: BorderRadius.circular(KhatirRadius.card),
            ),
            child: Column(
              children: [
                const Text('🌟', style: TextStyle(fontSize: 48)),
                const SizedBox(height: KhatirSpacing.s2),
                Text(
                  l10n.ten_record_trusted,
                  style: AppTextStyles.accent.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: KhatirSpacing.s2),
                Text(
                  'ভালো ভাড়াটিয়া রেকর্ড',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // Stats grid (only if record exists).
          if (record != null) ...[
            const SizedBox(height: KhatirSpacing.s3),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: KhatirSpacing.s2,
              mainAxisSpacing: KhatirSpacing.s2,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  value: record!.onTimeMonths.toString(),
                  label: l10n.ten_record_on_time,
                ),
                _StatCard(
                  value: record!.completedLeases.toString(),
                  label: l10n.ten_record_leases,
                ),
                _StatCard(
                  value: record!.averageRating.toStringAsFixed(1),
                  label: l10n.ten_record_avg_rating,
                ),
                _StatCard(
                  value: record!.disputes.toString(),
                  label: l10n.ten_record_disputes,
                ),
              ],
            ),
          ],

          const SizedBox(height: KhatirSpacing.s4),

          // Star rating.
          Text(l10n.ten_record_rating, style: AppTextStyles.labelLarge),
          const SizedBox(height: KhatirSpacing.s2),
          Row(
            children: List.generate(5, (i) {
              final filled = i < rating.value;
              return GestureDetector(
                onTap: () => rating.value = i + 1,
                child: Padding(
                  padding: const EdgeInsets.only(right: KhatirSpacing.s2),
                  child: Icon(
                    filled ? Icons.star : Icons.star_outline,
                    size: 32,
                    color: filled
                        ? KhatirColors.butterDk
                        : KhatirColors.lineDk,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: KhatirSpacing.s4),

          // Notes field.
          Text(l10n.ten_record_notes, style: AppTextStyles.labelLarge),
          const SizedBox(height: KhatirSpacing.s2),
          TextField(
            controller: notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: l10n.ten_record_notes_hint,
              hintStyle: AppTextStyles.bodySmall,
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

          const SizedBox(height: KhatirSpacing.s4),

          // Privacy notice.
          Container(
            padding: const EdgeInsets.all(KhatirSpacing.s3),
            decoration: BoxDecoration(
              color: KhatirColors.butterBg,
              borderRadius: BorderRadius.circular(KhatirRadius.card),
              border: Border.all(color: KhatirColors.line),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: KhatirColors.roseDk,
                ),
                const SizedBox(width: KhatirSpacing.s2),
                Expanded(
                  child: Text(
                    l10n.ten_record_private_note,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: KhatirColors.mutedDk,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: KhatirSpacing.s4),

          // Consent toggle.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KhatirSpacing.s4,
              vertical: KhatirSpacing.s3,
            ),
            decoration: BoxDecoration(
              color: KhatirColors.card,
              borderRadius: BorderRadius.circular(KhatirRadius.card),
              border: Border.all(color: KhatirColors.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.ten_record_consent,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                Switch(
                  value: consent.value,
                  onChanged: (v) => consent.value = v,
                  activeColor: KhatirColors.sage,
                ),
              ],
            ),
          ),

          const SizedBox(height: KhatirSpacing.s5),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSaving.value ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: KhatirColors.sage,
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
              child: isSaving.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.ten_record_save),
            ),
          ),
          const SizedBox(height: KhatirSpacing.s6),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        border: Border.all(color: KhatirColors.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: KhatirColors.sageDk,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: KhatirSpacing.s1),
          Text(
            label,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
