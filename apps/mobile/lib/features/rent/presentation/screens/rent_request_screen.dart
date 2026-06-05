import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';

/// The outcome a completed rent-request action emits — the test seam that lets
/// widget tests assert the entered terms + chosen action without hitting the
/// network. Mirrors the create call the rent endpoint consumes (T-003): a lease,
/// an [amount] and a `YYYY-MM` [period]. [markReceived] records which button was
/// tapped (Send WhatsApp link vs. Mark received cash).
class RentRequestDraft {
  const RentRequestDraft({
    required this.leaseId,
    required this.amount,
    required this.period,
    required this.markReceived,
  });

  final String leaseId;
  final double amount;
  final String period;
  final bool markReceived;
}

/// Rent-request screen (EPIC-07 T-011), reached at `/rent/request` from the
/// unit-detail "Ask for rent" CTA (active lease) and the home late-payers list
/// (T-014). It asks the landlord to request rent for a due period and either
/// send the tenant a link (WhatsApp/SMS) or record an off-platform cash payment.
///
/// Per the `rentReq` prototype (screens-landlord2.js): an "Ask for rent" hero
/// that reassures the tenant gets a WhatsApp link even without the app, then the
/// amount + period inputs and the two actions. The colours/spacing/radius/fonts
/// all come from the design tokens (no prototype hex/px); numerals stay as typed.
///
/// The landlord is server-derived from the lease and is never collected here.
/// Sending runs [RentRepository.createManual] then [RentRequestController.send]
/// (create + deliver the link) and routes to the verify queue; "Mark received"
/// runs createManual then [RentRequestController.markReceived] (settle the cash
/// payment) and routes to the receipt. Failures surface as a friendly snackbar
/// (T-011 §8) rather than the raw error.
///
/// States: **data** (the form, idle), **sending** (a spinner on the tapped
/// action, both disabled), **error** (snackbar, form re-enabled to retry).
class RentRequestScreen extends HookConsumerWidget {
  const RentRequestScreen({
    super.key,
    required this.leaseId,
    this.initialAmount,
    this.initialPeriod,
    this.onProceed,
  });

  /// The active lease rent is being requested for — always supplied (the screen
  /// is launched in lease context). Threaded into the create call as `lease`.
  final String leaseId;

  /// Optional prefill for the amount field (the lease's monthly rent). Left
  /// editable so a partial / adjusted ask is possible.
  final double? initialAmount;

  /// Optional prefill for the `YYYY-MM` period (the due billing month).
  final String? initialPeriod;

  /// Test seam: invoked with the entered [RentRequestDraft] when an action
  /// button is tapped and validation passes. When null (the default, and what
  /// the router supplies) the screen runs the real create(+send|+mark-received)
  /// flow and routes onward on success.
  final Future<void> Function(RentRequestDraft draft)? onProceed;

  static const String routePath = '/rent/request';
  static const String routeName = 'rentRequest';

  /// Route the verify queue lives on (T-013) — where a sent request lands so the
  /// landlord can verify the tenant's proof.
  static const String verifyQueuePath = '/landlord/rent';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final amountCtrl = useTextEditingController(
      text: (initialAmount != null && initialAmount! > 0)
          ? initialAmount!.round().toString()
          : '',
    );
    final periodCtrl = useTextEditingController(text: initialPeriod ?? '');
    final busy = useState<bool>(false);
    // Which action is mid-flight, so only its button shows the spinner.
    final busyMarkReceived = useState<bool>(false);
    final formKey = useMemoized(GlobalKey<FormState>.new);

    Future<void> run({required bool markReceived}) async {
      final form = formKey.currentState;
      if (form == null || !form.validate()) return;
      final amount = double.parse(amountCtrl.text.trim());
      final period = periodCtrl.text.trim();

      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.maybeOf(context);

      busy.value = true;
      busyMarkReceived.value = markReceived;
      try {
        final draft = RentRequestDraft(
          leaseId: leaseId,
          amount: amount,
          period: period,
          markReceived: markReceived,
        );
        if (onProceed != null) {
          await onProceed!(draft);
          return;
        }
        // Create the request, then either send the tenant link or settle as a
        // cash payment — both create flows funnel through the repository (a new
        // request has no id yet), then the per-request controller drives the
        // lifecycle transition.
        final repo = ref.read(rentRepositoryProvider);
        final RentRequest created = await repo.createManual(
          leaseId: leaseId,
          amount: amount,
          period: period,
        );
        final controller =
            ref.read(rentRequestControllerProvider(created.id).notifier);
        if (markReceived) {
          await controller.markReceived();
        } else {
          await controller.send();
        }
        // Keep the queue fresh so the new/settled request shows on return.
        ref.invalidate(rentQueueProvider);

        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                markReceived
                    ? l10n.rent_request_received
                    : l10n.rent_request_sent,
              ),
            ),
          );
        // Send → the verify queue (mark-received settles in place, then returns
        // to the queue too — the receipt is reached from there via its row).
        router?.go(verifyQueuePath);
      } on ApiException {
        _reportError(messenger, l10n);
      } catch (_) {
        _reportError(messenger, l10n);
      } finally {
        busy.value = false;
        busyMarkReceived.value = false;
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
          l10n.rent_request_title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              KhatirSpacing.s5,
              KhatirSpacing.s4,
              KhatirSpacing.s5,
              KhatirSpacing.s6,
            ),
            children: [
              // ── Hero ──────────────────────────────────────────────────────
              const _Hero(emoji: '📤'),
              const SizedBox(height: KhatirSpacing.s3),
              Text(
                l10n.rent_request_heading,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: KhatirSpacing.s2),
              Text(
                l10n.rent_request_subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: KhatirColors.mutedDk, height: 1.5),
              ),
              const SizedBox(height: KhatirSpacing.s6),

              // ── Amount ────────────────────────────────────────────────────
              _Field(
                key: const ValueKey('rentAmount'),
                controller: amountCtrl,
                label: l10n.rent_request_amount,
                icon: Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final amount = double.tryParse((value ?? '').trim());
                  if (amount == null || amount <= 0) {
                    return l10n.rent_request_err_amount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: KhatirSpacing.s4),

              // ── Period ────────────────────────────────────────────────────
              _Field(
                key: const ValueKey('rentPeriod'),
                controller: periodCtrl,
                label: l10n.rent_request_period,
                hint: l10n.rent_request_period_hint,
                icon: Icons.event_outlined,
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  final period = (value ?? '').trim();
                  if (!_periodPattern.hasMatch(period)) {
                    return l10n.rent_request_err_period;
                  }
                  return null;
                },
              ),
              const SizedBox(height: KhatirSpacing.s6),

              // ── Actions ───────────────────────────────────────────────────
              _ActionButton(
                key: const ValueKey('rentSend'),
                label: l10n.rent_send_whatsapp,
                icon: Icons.send_outlined,
                filled: true,
                busy: busy.value && !busyMarkReceived.value,
                onPressed:
                    busy.value ? null : () => run(markReceived: false),
              ),
              const SizedBox(height: KhatirSpacing.s3),
              _ActionButton(
                key: const ValueKey('rentMarkReceived'),
                label: l10n.rent_mark_received,
                icon: Icons.check_circle_outline,
                filled: false,
                busy: busy.value && busyMarkReceived.value,
                onPressed:
                    busy.value ? null : () => run(markReceived: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reportError(ScaffoldMessengerState messenger, AppLocalizations l10n) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.rent_request_error)));
  }
}

/// A `YYYY-MM` period matcher (month 01–12), kept lenient on the year so it
/// accepts any 4-digit year the landlord types.
final RegExp _periodPattern = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');

/// The circular emoji hero badge that opens the screen, matching the prototype's
/// `emojiHero` composition (a soft sage disc with a large glyph).
class _Hero extends StatelessWidget {
  const _Hero({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: KhatirColors.sageBg,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 34)),
      ),
    );
  }
}

/// A single editable text field, matching the shared form-field composition
/// (white card, line border, sage focus).
class _Field extends StatelessWidget {
  const _Field({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.md);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: KhatirColors.mutedDk,
          fontWeight: FontWeight.w600,
        ),
        hintStyle:
            AppTextStyles.bodySmall.copyWith(color: KhatirColors.muted),
        prefixIcon: Icon(icon, size: 20, color: KhatirColors.sageDk),
        filled: true,
        fillColor: KhatirColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KhatirSpacing.s4,
          vertical: KhatirSpacing.s3,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: KhatirColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: KhatirColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: KhatirColors.sage, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: KhatirColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: KhatirColors.danger, width: 2),
        ),
      ),
    );
  }
}

/// A full-width pill action — [filled] sage for the primary send action,
/// outlined for the secondary mark-received action. Shows a spinner when [busy].
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.filled,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(KhatirRadius.button),
    );
    const padding = EdgeInsets.symmetric(vertical: KhatirSpacing.s4);
    final spinner = SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: filled ? KhatirColors.cream : KhatirColors.sageDk,
      ),
    );
    final child = busy
        ? spinner
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: KhatirSpacing.s2),
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    if (filled) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: KhatirColors.sage,
            foregroundColor: KhatirColors.cream,
            disabledBackgroundColor: KhatirColors.sage,
            disabledForegroundColor: KhatirColors.cream,
            elevation: 0,
            padding: padding,
            textStyle: AppTextStyles.labelLarge,
            shape: shape,
          ),
          child: child,
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: KhatirColors.sageDk,
          padding: padding,
          textStyle: AppTextStyles.labelLarge,
          side: const BorderSide(color: KhatirColors.sage),
          shape: shape,
        ),
        child: child,
      ),
    );
  }
}
