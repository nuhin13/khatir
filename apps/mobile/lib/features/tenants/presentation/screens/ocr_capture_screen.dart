import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/extracted_tenant.dart';
import '../../data/tenants_providers.dart';
import 'ocr_review_args.dart';

/// NID OCR capture stage, mirroring the `ocr` prototype capture state
/// (`proto/screens-landlord2.js` → `reg('ocr')`, `!ocrScanned` branch).
///
/// Flow: the user frames their NID and taps **Take photo** (camera) or
/// **From gallery**. The picked image is uploaded to `POST /tenants/ocr`; while
/// the upload + OCR run we show a processing state; on success we navigate to
/// the OCR review screen (T-011) carrying the extracted fields + `photo_ref`;
/// on failure we show an error with retry. The image is held only in memory for
/// the upload and is never persisted on the device (T-010 §15).
///
/// All colors/spacing/radii come from the design tokens.
class OcrCaptureScreen extends HookConsumerWidget {
  const OcrCaptureScreen({super.key, this.unitId});

  /// Optional target unit id threaded from the add-tenant chooser, passed on to
  /// the review screen so the downstream save knows the unit context.
  final String? unitId;

  /// Sub-route under `/tenants/add`.
  static const String routePath = 'ocr';
  static const String routeName = 'tenantsAddOcr';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Capture-stage state machine: idle → uploading → (navigate | error).
    final busy = useState<bool>(false);
    final error = useState<bool>(false);

    Future<void> capture(Future<PickedImage?> Function() pick) async {
      if (busy.value) return;
      error.value = false;
      final PickedImage? picked;
      try {
        picked = await pick();
      } catch (_) {
        error.value = true;
        return;
      }
      if (picked == null) return; // user cancelled — stay on capture.

      busy.value = true;
      try {
        final ExtractedTenant result = await ref
            .read(tenantRepositoryProvider)
            .ocrExtract(picked.bytes, filename: picked.filename);
        if (!context.mounted) return;
        // Success → OCR review (T-011) with the extracted fields + photo_ref.
        context.pushReplacementNamed(
          OcrReviewArgs.routeName,
          queryParameters: unitId == null ? const {} : {'unit': unitId!},
          extra: OcrReviewArgs(extracted: result, unitId: unitId),
        );
      } catch (_) {
        if (!context.mounted) return;
        error.value = true;
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    final picker = ref.read(imagePickerServiceProvider);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.ocr_capture_title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            KhatirSpacing.s5,
            KhatirSpacing.s4,
            KhatirSpacing.s5,
            KhatirSpacing.s6,
          ),
          children: [
            Center(
              child: Text(
                l10n.ocr_capture_heading,
                style: AppTextStyles.accent.copyWith(
                  fontSize: 25,
                  color: KhatirColors.sageDk,
                ),
              ),
            ),
            const SizedBox(height: KhatirSpacing.s3),
            const _CameraFrame(),
            const SizedBox(height: KhatirSpacing.s4),
            _PrivacyNote(text: l10n.ocr_privacy_note),
            const SizedBox(height: KhatirSpacing.s5),
            if (busy.value)
              const _ProcessingState(key: ValueKey('ocrProcessing'))
            else if (error.value)
              _ErrorState(
                key: const ValueKey('ocrError'),
                onRetry: () => capture(picker.pickFromCamera),
              )
            else ...[
              _PrimaryAction(
                key: const ValueKey('ocrTakePhoto'),
                icon: Icons.photo_camera_rounded,
                label: l10n.ocr_take_photo,
                onTap: () => capture(picker.pickFromCamera),
              ),
              const SizedBox(height: KhatirSpacing.s3),
              _SecondaryAction(
                key: const ValueKey('ocrFromGallery'),
                icon: Icons.photo_library_outlined,
                label: l10n.ocr_from_gallery,
                onTap: () => capture(picker.pickFromGallery),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The dark NID viewfinder card: a dashed frame + scan line over a dark plate,
/// matching the prototype's capture aesthetic.
class _CameraFrame extends StatelessWidget {
  const _CameraFrame();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(KhatirRadius.card),
      child: AspectRatio(
        aspectRatio: 1.58,
        child: ColoredBox(
          color: KhatirColors.ink,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(KhatirSpacing.s5),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(KhatirRadius.card),
                      border: Border.all(
                        color: KhatirColors.cream.withValues(alpha: 0.4),
                        width: 3,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KhatirSpacing.s5,
                ),
                child: Container(height: 2, color: KhatirColors.butter),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📇', style: TextStyle(fontSize: 42)),
                  const SizedBox(height: KhatirSpacing.s2),
                  Text(
                    l10n.ocr_frame_hint,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: KhatirColors.cream.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The sage privacy reassurance card ("photo never leaves your phone").
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined,
              size: 20, color: KhatirColors.sageDk),
          const SizedBox(width: KhatirSpacing.s3),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: KhatirColors.sageDk,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The filled sage "Take photo" call to action.
class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
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

/// The outlined "From gallery" fallback action.
class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: KhatirColors.sageDk,
          side: const BorderSide(color: KhatirColors.sage, width: 1.5),
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

/// Loading state while the image uploads and OCR runs.
class _ProcessingState extends StatelessWidget {
  const _ProcessingState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        const SizedBox(height: KhatirSpacing.s2),
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: KhatirColors.sage,
          ),
        ),
        const SizedBox(height: KhatirSpacing.s4),
        Text(
          l10n.ocr_processing,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: KhatirColors.sageDk,
          ),
        ),
      ],
    );
  }
}

/// Error state with a retry action when upload/OCR fails.
class _ErrorState extends StatelessWidget {
  const _ErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(KhatirSpacing.s4),
          decoration: BoxDecoration(
            color: KhatirColors.dangerBg,
            borderRadius: BorderRadius.circular(KhatirRadius.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline,
                  size: 20, color: KhatirColors.danger),
              const SizedBox(width: KhatirSpacing.s3),
              Expanded(
                child: Text(
                  l10n.ocr_error,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: KhatirColors.danger,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KhatirSpacing.s4),
        _PrimaryAction(
          key: const ValueKey('ocrRetry'),
          icon: Icons.refresh_rounded,
          label: l10n.ocr_retry,
          onTap: onRetry,
        ),
      ],
    );
  }
}
