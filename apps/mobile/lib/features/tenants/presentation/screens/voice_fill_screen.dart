import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/config/flags_provider.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/extracted_tenant.dart';
import '../../data/tenants_providers.dart';
import 'ocr_review_args.dart';

/// Voice tenant-entry stage, mirroring the `voice` prototype
/// (`proto/screens-landlord2.js` → `reg('voice')`, the `!voiceDone` record
/// state).
///
/// Flow: the landlord taps the mic and speaks the tenant's details in Bangla;
/// the clip is recorded (the recorder owns the mic-permission prompt), uploaded
/// to `POST /tenants/voice`, transcribed + extracted by ASR, and on success we
/// navigate to the OCR review screen (T-011) — reused unchanged — carrying the
/// extracted fields for confirmation. Voice has no stored artefact, so the
/// `photo_ref` is empty; the audio clip is uploaded then discarded and is never
/// persisted on the device (T-012 §14).
///
/// Reaching this screen is gated by the `voice_tenant_entry` flag at the chooser
/// (T-009); a defensive flag check here keeps a deep link from bypassing the
/// gate — when the flag is off the screen renders an "unavailable" state instead
/// of the recorder.
///
/// All colors/spacing/radii/fonts come from the design tokens.
class VoiceFillScreen extends HookConsumerWidget {
  const VoiceFillScreen({super.key, this.unitId});

  /// Optional target unit id threaded from the add-tenant chooser, passed on to
  /// the review screen so the downstream save knows the unit context.
  final String? unitId;

  /// Sub-route under `/tenants/add`.
  static const String routePath = 'voice';
  static const String routeName = 'tenantsAddVoice';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Defensive flag gate — the chooser (T-009) already hides the entry when
    // off; this stops a deep link from reaching the recorder. Read through the
    // generic FlagsProvider; falls back to the permissive default (enabled)
    // while the config resolves / if it fails, matching the backend's
    // "default on" behaviour.
    final voiceEnabled =
        ref.watch(flagsProvider).isEnabled('voice_tenant_entry', orElse: true);

    // Recording-stage state machine: idle → recording → processing →
    // (navigate | error).
    final stage = useState<_VoiceStage>(_VoiceStage.idle);
    final recorder = ref.read(audioRecorderServiceProvider);

    // Stop any in-flight recording and release the recorder on teardown so a
    // half-recorded clip never lingers (privacy, §14).
    useEffect(() => () => recorder.dispose(), [recorder]);

    Future<void> upload(RecordedAudio audio) async {
      stage.value = _VoiceStage.processing;
      try {
        final ExtractedTenant result = await ref
            .read(tenantRepositoryProvider)
            .voiceExtract(audio.bytes, filename: audio.filename);
        if (!context.mounted) return;
        // Success → reuse the OCR review screen (T-011) with the extracted
        // fields. Voice carries no photo_ref (empty) — the review form is the
        // same; only the source differs.
        context.pushReplacementNamed(
          OcrReviewArgs.routeName,
          queryParameters: unitId == null ? const {} : {'unit': unitId!},
          extra: OcrReviewArgs(extracted: result, unitId: unitId),
        );
      } catch (_) {
        if (!context.mounted) return;
        stage.value = _VoiceStage.error;
      }
    }

    Future<void> startRecording() async {
      if (stage.value == _VoiceStage.recording ||
          stage.value == _VoiceStage.processing) {
        return;
      }
      final started = await recorder.start();
      if (!context.mounted) return;
      if (!started) {
        // Permission denied / unavailable.
        stage.value = _VoiceStage.error;
        return;
      }
      stage.value = _VoiceStage.recording;
    }

    Future<void> stopRecording() async {
      if (stage.value != _VoiceStage.recording) return;
      final RecordedAudio? audio;
      try {
        audio = await recorder.stop();
      } catch (_) {
        if (!context.mounted) return;
        stage.value = _VoiceStage.error;
        return;
      }
      if (!context.mounted) return;
      if (audio == null) {
        // Nothing captured — return to idle so the user can retry.
        stage.value = _VoiceStage.idle;
        return;
      }
      await upload(audio);
    }

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.voice_title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            KhatirSpacing.s5,
            KhatirSpacing.s5,
            KhatirSpacing.s5,
            KhatirSpacing.s6,
          ),
          children: [
            if (!voiceEnabled)
              _UnavailableState(
                key: const ValueKey('voiceUnavailable'),
                text: l10n.voice_unavailable,
              )
            else ...[
              Center(
                child: Text(
                  l10n.voice_heading,
                  style: AppTextStyles.accent.copyWith(
                    fontSize: 28,
                    color: KhatirColors.sageDk,
                  ),
                ),
              ),
              const SizedBox(height: KhatirSpacing.s2),
              Center(
                child: Text(
                  l10n.voice_tap_to_record,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: KhatirSpacing.s6),
              if (stage.value == _VoiceStage.processing)
                const _ProcessingState(key: ValueKey('voiceProcessing'))
              else
                _MicButton(
                  recording: stage.value == _VoiceStage.recording,
                  idleLabel: l10n.voice_tap_to_record,
                  recordingLabel: l10n.voice_recording,
                  onStart: startRecording,
                  onStop: stopRecording,
                ),
              const SizedBox(height: KhatirSpacing.s5),
              if (stage.value == _VoiceStage.error) ...[
                _ErrorState(
                  key: const ValueKey('voiceError'),
                  text: l10n.voice_error,
                  retryLabel: l10n.voice_tap_to_record,
                  onRetry: () => stage.value = _VoiceStage.idle,
                ),
                const SizedBox(height: KhatirSpacing.s5),
              ],
              _ExampleCard(
                title: l10n.voice_example_label,
                example: l10n.voice_example,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Recording-stage states for the voice screen.
enum _VoiceStage { idle, recording, processing, error }

/// The round mic call-to-action. Hold-to-talk: press starts recording, release
/// stops + uploads. A rose halo pulses while recording (matching the prototype).
class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.recording,
    required this.idleLabel,
    required this.recordingLabel,
    required this.onStart,
    required this.onStop,
  });

  /// Whether the parent state machine considers a recording in progress (drives
  /// the visual). The press lifecycle itself is tracked locally so a fast
  /// tap-down/up reliably pairs a [onStart] with a [onStop].
  final bool recording;
  final String idleLabel;
  final String recordingLabel;
  final Future<void> Function() onStart;
  final Future<void> Function() onStop;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> {
  // The in-flight start, held so a release awaits it before stopping — a fast
  // tap-down/up then reliably pairs one [onStart] with one [onStop], regardless
  // of when the parent's `recording` prop rebuilds.
  Future<void>? _starting;

  Future<void> _press() async {
    if (_starting != null) return;
    final start = widget.onStart();
    _starting = start;
    await start;
  }

  Future<void> _release() async {
    final start = _starting;
    if (start == null) return;
    _starting = null;
    await start; // ensure the recording actually started before stopping.
    await widget.onStop();
  }

  @override
  Widget build(BuildContext context) {
    final recording = widget.recording;
    return Column(
      children: [
        GestureDetector(
          key: const ValueKey('voiceMic'),
          onTapDown: (_) => _press(),
          onTapUp: (_) => _release(),
          onTapCancel: _release,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 158,
            height: 158,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [KhatirColors.rose, KhatirColors.roseDk],
              ),
              boxShadow: [
                BoxShadow(
                  color: KhatirColors.roseBg,
                  spreadRadius: recording ? 22 : 14,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              recording ? Icons.stop_rounded : Icons.mic_rounded,
              size: 62,
              color: KhatirColors.cream,
            ),
          ),
        ),
        const SizedBox(height: KhatirSpacing.s5),
        Text(
          recording ? widget.recordingLabel : widget.idleLabel,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: recording ? KhatirColors.roseDk : KhatirColors.mutedDk,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Loading state while the clip uploads and ASR runs.
class _ProcessingState extends StatelessWidget {
  const _ProcessingState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
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
          l10n.voice_processing,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: KhatirColors.sageDk,
          ),
        ),
      ],
    );
  }
}

/// Error state (recording failed / permission denied / upload failed) with a
/// retry that returns to the idle recorder.
class _ErrorState extends StatelessWidget {
  const _ErrorState({
    super.key,
    required this.text,
    required this.retryLabel,
    required this.onRetry,
  });

  final String text;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
                  text,
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
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const ValueKey('voiceRetry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(retryLabel),
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
        ),
      ],
    );
  }
}

/// The butter "example phrasing" hint card from the prototype.
class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.title, required this.example});

  final String title;
  final String example;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.butterBg,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: KhatirColors.mutedDk,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: KhatirSpacing.s1),
          Text(
            example,
            style: AppTextStyles.accent.copyWith(
              fontSize: 17,
              height: 1.4,
              color: KhatirColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the `voice_tenant_entry` flag is off but the screen is reached
/// via a deep link — keeps the flag authoritative everywhere.
class _UnavailableState extends StatelessWidget {
  const _UnavailableState({super.key, required this.text});

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
          const Icon(Icons.info_outline, size: 20, color: KhatirColors.sageDk),
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
