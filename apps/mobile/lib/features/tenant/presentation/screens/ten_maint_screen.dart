import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/tenant_enums.dart';
import '../../data/tenant_providers.dart';

/// Tenant maintenance report screen (EPIC-19 T-008), per the `tenMaint`
/// prototype (`proto/screens-other.js` → `reg('tenMaint')`).
///
/// Category selector (water / electrical / paint / other), description
/// textarea, optional photo picker. Submits to the landlord maintenance
/// queue via `POST /api/v1/maintenance/reports`.
///
/// States: loading (submitting) / error / data (form).
class TenMaintScreen extends HookConsumerWidget {
  const TenMaintScreen({super.key});

  static const String routePath = '/tenant/maintenance';
  static const String routeName = 'tenantMaintenance';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final descController = useTextEditingController();
    final selectedCategory =
        useState<TenantMaintenanceCategory>(TenantMaintenanceCategory.other);
    final isSubmitting = useState(false);
    final photoRef = useState<String?>(null);

    final categories = [
      _Category(
        label: l10n.ten_maint_cat_plumbing,
        value: TenantMaintenanceCategory.plumbing,
      ),
      _Category(
        label: l10n.ten_maint_cat_electrical,
        value: TenantMaintenanceCategory.electrical,
      ),
      _Category(
        label: l10n.ten_maint_cat_paint,
        value: TenantMaintenanceCategory.paint,
      ),
      _Category(
        label: l10n.ten_maint_cat_other,
        value: TenantMaintenanceCategory.other,
      ),
    ];

    Future<void> _pickPhoto() async {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // In production: upload image and get object-storage ref.
        photoRef.value = 'stub-photo-ref';
      }
    }

    Future<void> _submit() async {
      if (isSubmitting.value) return;
      final desc = descController.text.trim();
      if (desc.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('বিবরণ লিখুন · Please add a description')),
        );
        return;
      }
      isSubmitting.value = true;
      try {
        final controller = ref.read(myMaintenanceControllerProvider.notifier);
        await controller.submit(
          description: desc,
          category: selectedCategory.value,
          photoRef: photoRef.value,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('অনুরোধ পাঠানো হয়েছে · Request submitted'),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'মেরামত চাই · Maintenance',
          style: AppTextStyles.titleLarge,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KhatirSpacing.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji hero: "What needs fixing?"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(KhatirSpacing.s4),
              decoration: BoxDecoration(
                color: KhatirColors.card,
                borderRadius: BorderRadius.circular(KhatirRadius.card),
                border: Border.all(color: KhatirColors.line),
              ),
              child: Row(
                children: [
                  const Text('🔧', style: TextStyle(fontSize: 40)),
                  const SizedBox(width: KhatirSpacing.s3),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What needs fixing?',
                        style: AppTextStyles.titleMedium,
                      ),
                      Text(
                        'সমস্যা জানান',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: KhatirSpacing.s4),

            // Category selector.
            Text(l10n.ten_maint_category, style: AppTextStyles.labelLarge),
            const SizedBox(height: KhatirSpacing.s2),
            Wrap(
              spacing: KhatirSpacing.s2,
              runSpacing: KhatirSpacing.s2,
              children: categories.map((cat) {
                final selected = selectedCategory.value == cat.value;
                return GestureDetector(
                  onTap: () => selectedCategory.value = cat.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KhatirSpacing.s3,
                      vertical: KhatirSpacing.s2,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? KhatirColors.rose
                          : KhatirColors.roseBg,
                      borderRadius: BorderRadius.circular(KhatirRadius.chip),
                    ),
                    child: Text(
                      cat.label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: selected ? Colors.white : KhatirColors.roseDk,
                        fontWeight: FontWeight.w700,
                        fontFamily: KhatirFonts.title,
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),

            const SizedBox(height: KhatirSpacing.s4),

            // Description field.
            Text(l10n.ten_maint_describe, style: AppTextStyles.labelLarge),
            const SizedBox(height: KhatirSpacing.s2),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.ten_maint_description_hint,
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

            const SizedBox(height: KhatirSpacing.s3),

            // Photo picker.
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                padding: const EdgeInsets.all(KhatirSpacing.s3),
                decoration: BoxDecoration(
                  color: KhatirColors.card,
                  borderRadius: BorderRadius.circular(KhatirRadius.card),
                  border: Border.all(
                    color: photoRef.value != null
                        ? KhatirColors.sage
                        : KhatirColors.lineDk,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: KhatirColors.sageBg,
                        borderRadius: BorderRadius.circular(KhatirRadius.sm),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        size: 20,
                        color: KhatirColors.sageDk,
                      ),
                    ),
                    const SizedBox(width: KhatirSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            photoRef.value != null
                                ? 'ছবি যোগ হয়েছে · Photo added'
                                : l10n.ten_maint_photo,
                            style: AppTextStyles.labelLarge,
                          ),
                          Text(
                            l10n.ten_maint_photo_optional,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: KhatirSpacing.s5),

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
                label: Text(l10n.ten_maint_submit),
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
            const SizedBox(height: KhatirSpacing.s6),
          ],
        ),
      ),
    );
  }
}

class _Category {
  const _Category({required this.label, required this.value});

  final String label;
  final TenantMaintenanceCategory value;
}
