import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';

/// Typed `extra` payload the router carries into [VerifyPaymentScreen] from a
/// queue row: the claiming tenant's display name and their submitted
/// [PaymentProof] (the rent detail endpoint does not yet surface the proof, so
/// the queue passes what it already loaded). Both are optional.
class VerifyPaymentArgs {
  const VerifyPaymentArgs({this.tenantName, this.proof});

  final String? tenantName;
  final PaymentProof? proof;
}

/// The action a completed verify-payment flow emits — the test seam that lets a
/// widget test assert which action ran (and, on reject, with what reason)
/// without hitting the network or routing. [reason] is non-null only on a
/// reject.
enum VerifyAction { verify, reject }

/// Outcome handed to the [VerifyPaymentScreen.onAction] test seam: which action
/// the landlord took and, for a reject, the entered [reason].
class VerifyOutcome {
  const VerifyOutcome({required this.action, this.reason});

  final VerifyAction action;
  final String? reason;
}

/// Verify-payment screen (EPIC-07 T-012), reached at `/rent/:id/verify` from the
/// rent-collection queue. It shows the tenant's submitted proof (a transaction
/// id / note and, when present, a screenshot fetched via its signed URL) for one
/// rent request and lets the landlord verify it (→ a receipt is generated) or
/// reject it with a reason.
///
/// Per the `verifyPay` prototype (screens-landlord2.js): a soft butter claim
/// card ("X says they paid"), the submitted-proof viewer, then the two actions
/// (Received / Not yet received). All colours/spacing/radius/fonts come from the
/// design tokens (no prototype hex/px); the requested amount comes back from the
/// `RentRequest`.
///
/// The request is loaded via [rentRequestControllerProvider] (a single source of
/// truth shared with the lifecycle transitions). The screenshot proof is fetched
/// via a signed URL — never embedded raw — so [PaymentProof.photoRef] is treated
/// as that signed URL and loaded with [Image.network]; a load failure degrades
/// to a friendly placeholder. The proof itself is not yet surfaced by the rent
/// detail endpoint, so it is supplied to the screen (router `extra` / future
/// wiring); when absent the viewer shows a "no proof yet" placeholder.
///
/// States: **data** (proof + actions), **loading** (the request is resolving),
/// **load error** (a retry), **verifying** (a spinner on the tapped action, both
/// disabled), **action error** (a friendly snackbar, actions re-enabled).
///
/// Navigation: verify → the receipt (`/rent/:id/receipt`, T-013); reject → back
/// to the queue.
class VerifyPaymentScreen extends HookConsumerWidget {
  const VerifyPaymentScreen({
    super.key,
    required this.requestId,
    this.tenantName,
    this.proof,
    this.onAction,
  });

  /// The rent request being verified — always supplied (the screen is launched
  /// from a queue row at `/rent/:id/verify`). Drives the load + the lifecycle
  /// transitions.
  final String requestId;

  /// Optional display name of the claiming tenant, shown in the claim card.
  /// Falls back to a neutral label when absent (the rent detail endpoint does
  /// not yet surface the tenant).
  final String? tenantName;

  /// The tenant's submitted proof, supplied by the caller (router `extra` /
  /// future wiring) since the rent detail endpoint does not yet surface it. When
  /// null the proof viewer shows a "no proof yet" placeholder. Its [photoRef] is
  /// treated as a signed URL and loaded with [Image.network] (never raw bytes).
  final PaymentProof? proof;

  /// Test seam: invoked with the chosen [VerifyOutcome] when an action completes
  /// validation. When null (the default, and what the router supplies) the
  /// screen runs the real verify / reject transition and routes onward.
  final Future<void> Function(VerifyOutcome outcome)? onAction;

  static const String routePath = '/rent/:id/verify';
  static const String routeName = 'verifyPayment';

  /// The receipt route a verified request lands on (T-013) — `:id` is filled
  /// with [requestId].
  static String receiptPathFor(String id) => '/rent/$id/receipt';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final requestAsync = ref.watch(rentRequestControllerProvider(requestId));

    // Which action is mid-flight (so only its button shows the spinner), or null
    // when idle.
    final busyAction = useState<VerifyAction?>(null);

    Future<void> run(VerifyAction action, {String? reason}) async {
      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.maybeOf(context);

      busyAction.value = action;
      try {
        if (onAction != null) {
          await onAction!(VerifyOutcome(action: action, reason: reason));
          return;
        }
        final controller =
            ref.read(rentRequestControllerProvider(requestId).notifier);
        if (action == VerifyAction.verify) {
          await controller.verify();
        } else {
          await controller.reject(reason: reason!);
        }
        // Keep the queue fresh so the settled/rejected request updates on return.
        ref.invalidate(rentQueueProvider);

        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                action == VerifyAction.verify
                    ? l10n.verify_verified
                    : l10n.verify_rejected,
              ),
            ),
          );
        // Verify → the receipt; reject → back to the queue.
        if (action == VerifyAction.verify) {
          router?.go(receiptPathFor(requestId));
        } else {
          router?.pop();
        }
      } on ApiException {
        _reportError(messenger, l10n);
      } catch (_) {
        _reportError(messenger, l10n);
      } finally {
        busyAction.value = null;
      }
    }

    Future<void> onReject() async {
      final reason = await _promptReason(context, l10n);
      if (reason == null) return;
      await run(VerifyAction.reject, reason: reason);
    }

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.verify_title,
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
            tenantName: tenantName,
            proof: proof,
            busyAction: busyAction.value,
            onVerify: () => run(VerifyAction.verify),
            onReject: onReject,
          ),
        ),
      ),
    );
  }

  void _reportError(ScaffoldMessengerState messenger, AppLocalizations l10n) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.verify_error)));
  }
}

/// Opens the reject-reason dialog, returning the trimmed reason or null if the
/// landlord cancels. The reason is required (a non-empty trim) so a reject
/// always carries a stated cause (T-007 §7).
Future<String?> _promptReason(
  BuildContext context,
  AppLocalizations l10n,
) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _RejectReasonDialog(l10n: l10n),
  );
}

/// The populated verify body: the claim card, the proof viewer, and the
/// verify / reject actions.
class _Body extends StatelessWidget {
  const _Body({
    required this.request,
    required this.tenantName,
    required this.proof,
    required this.busyAction,
    required this.onVerify,
    required this.onReject,
  });

  final RentRequest request;
  final String? tenantName;
  final PaymentProof? proof;
  final VerifyAction? busyAction;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = busyAction != null;
    final displayName = (tenantName != null && tenantName!.trim().isNotEmpty)
        ? tenantName!.trim()
        : '—';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s5,
        KhatirSpacing.s4,
        KhatirSpacing.s5,
        KhatirSpacing.s6,
      ),
      children: [
        // ── Claim card ──────────────────────────────────────────────────────
        _ClaimCard(
          name: displayName,
          claim: l10n.verify_claim(displayName),
          subtitle: l10n.verify_amount_period(
            request.amount.round().toString(),
            request.period,
          ),
        ),
        const SizedBox(height: KhatirSpacing.s4),

        // ── Proof viewer ────────────────────────────────────────────────────
        Text(
          l10n.verify_proof,
          style: AppTextStyles.labelLarge.copyWith(
            color: KhatirColors.mutedDk,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: KhatirSpacing.s3),
        _ProofViewer(proof: proof, l10n: l10n),
        const SizedBox(height: KhatirSpacing.s6),

        // ── Actions ─────────────────────────────────────────────────────────
        _ActionButton(
          key: const ValueKey('verifyConfirm'),
          label: l10n.verify_confirm,
          icon: Icons.check_circle_outline,
          filled: true,
          busy: busyAction == VerifyAction.verify,
          onPressed: busy ? null : onVerify,
        ),
        const SizedBox(height: KhatirSpacing.s3),
        _ActionButton(
          key: const ValueKey('verifyReject'),
          label: l10n.verify_reject,
          icon: Icons.cancel_outlined,
          filled: false,
          busy: busyAction == VerifyAction.reject,
          onPressed: busy ? null : onReject,
        ),
      ],
    );
  }
}

/// The soft butter claim card: an avatar disc with the tenant initial, the claim
/// line and the amount/period subline. Matches the prototype `rowcard` on a
/// butter background.
class _ClaimCard extends StatelessWidget {
  const _ClaimCard({
    required this.name,
    required this.claim,
    required this.subtitle,
  });

  final String name;
  final String claim;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.trim().isNotEmpty && name.trim() != '—' ? name.trim()[0] : '?';
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.butterBg,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        border: Border.all(color: KhatirColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: KhatirColors.rose,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial.toUpperCase(),
              style: AppTextStyles.labelLarge.copyWith(
                color: KhatirColors.card,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: KhatirSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  claim,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: KhatirSpacing.s1),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: KhatirColors.mutedDk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The submitted-proof viewer: a card showing the screenshot (loaded from its
/// signed URL) with the transaction id / amount overlaid, or a friendly
/// placeholder when no proof was submitted or the image fails to load.
class _ProofViewer extends StatelessWidget {
  const _ProofViewer({required this.proof, required this.l10n});

  final PaymentProof? proof;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.card);
    final p = proof;

    if (p == null) {
      return _placeholder(
        key: const ValueKey('verifyProofNone'),
        icon: Icons.hourglass_empty,
        text: l10n.verify_proof_none,
      );
    }

    final hasImage = p.photoRef.trim().isNotEmpty;
    final hasTxn = p.value.trim().isNotEmpty;

    return Container(
      key: const ValueKey('verifyProof'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: radius,
        border: Border.all(color: KhatirColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasImage)
            SizedBox(
              height: 280,
              width: double.infinity,
              child: Image.network(
                p.photoRef,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stack) => _imageFailed(),
              ),
            ),
          if (hasTxn || !hasImage)
            Padding(
              padding: const EdgeInsets.all(KhatirSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasTxn)
                    _detailRow(l10n.verify_proof_txn, p.value.trim()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _imageFailed() {
    return Container(
      color: KhatirColors.sageBg,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined,
              size: 40, color: KhatirColors.mutedDk),
          const SizedBox(height: KhatirSpacing.s2),
          Text(
            l10n.verify_proof_image_failed,
            style:
                AppTextStyles.bodySmall.copyWith(color: KhatirColors.mutedDk),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: KhatirColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: KhatirSpacing.s2),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _placeholder({
    required Key key,
    required IconData icon,
    required String text,
  }) {
    return Container(
      key: key,
      height: 180,
      decoration: BoxDecoration(
        color: KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        border: Border.all(color: KhatirColors.line),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: KhatirColors.mutedDk),
          const SizedBox(height: KhatirSpacing.s2),
          Text(
            text,
            textAlign: TextAlign.center,
            style:
                AppTextStyles.bodySmall.copyWith(color: KhatirColors.mutedDk),
          ),
        ],
      ),
    );
  }
}

/// The reject-reason dialog: a required free-text reason the landlord must enter
/// before a reject is sent (T-007 §7). Returns the trimmed reason or null on
/// cancel.
class _RejectReasonDialog extends HookWidget {
  const _RejectReasonDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final error = useState<String?>(null);

    void submit() {
      final reason = controller.text.trim();
      if (reason.isEmpty) {
        error.value = l10n.verify_reason_required;
        return;
      }
      Navigator.of(context).pop(reason);
    }

    return AlertDialog(
      backgroundColor: KhatirColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KhatirRadius.lg),
      ),
      title: Text(
        l10n.verify_reason,
        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
      ),
      content: TextField(
        key: const ValueKey('verifyReasonField'),
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        style: AppTextStyles.bodyMedium,
        onChanged: (_) {
          if (error.value != null) error.value = null;
        },
        decoration: InputDecoration(
          hintText: l10n.verify_reason_hint,
          errorText: error.value,
          hintStyle:
              AppTextStyles.bodySmall.copyWith(color: KhatirColors.muted),
          filled: true,
          fillColor: KhatirColors.cream,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(KhatirRadius.md),
            borderSide: const BorderSide(color: KhatirColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(KhatirRadius.md),
            borderSide: const BorderSide(color: KhatirColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(KhatirRadius.md),
            borderSide: const BorderSide(color: KhatirColors.sage, width: 2),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: KhatirColors.mutedDk),
          child: Text(l10n.verify_reason_cancel),
        ),
        ElevatedButton(
          key: const ValueKey('verifyReasonSubmit'),
          onPressed: submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: KhatirColors.danger,
            foregroundColor: KhatirColors.card,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KhatirRadius.button),
            ),
          ),
          child: Text(l10n.verify_reason_submit),
        ),
      ],
    );
  }
}

/// The load-error state: a friendly message and a retry that re-fetches the
/// request.
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
              l10n.verify_load_error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: KhatirColors.mutedDk),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            OutlinedButton(
              key: const ValueKey('verifyRetry'),
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: KhatirColors.sageDk,
                side: const BorderSide(color: KhatirColors.sage),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KhatirRadius.button),
                ),
              ),
              child: Text(l10n.verify_retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-width pill action — [filled] sage for the primary verify action,
/// outlined for the secondary reject action. Shows a spinner when [busy].
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
