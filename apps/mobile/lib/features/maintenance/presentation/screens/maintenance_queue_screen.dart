import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/i18n/bangla_numerals.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/maintenance_enums.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';

/// The draft a resolve submission emits — the test seam that lets widget tests
/// assert the entered cost + note without hitting the network. Mirrors the
/// resolve call the maintenance endpoint consumes (T-002 / T-007
/// [MaintenanceRepository.resolve]): the request being resolved, the cost (which
/// becomes the auto-expense amount), and an optional resolution note.
class ResolveDraft {
  const ResolveDraft({
    required this.requestId,
    required this.cost,
    this.note,
  });

  final String requestId;
  final double cost;
  final String? note;
}

/// The landlord's maintenance queue (EPIC-08 T-010), per the `expenses`
/// prototype's "New requests" block (`proto/screens-landlord2.js` →
/// `reg('expenses')`): a list of open requests, each a card with the category
/// emoji, unit, description, a category chip and a "Resolve + cost" action that
/// opens the resolve dialog. Resolving records the [ResolveDraft.cost], which
/// auto-creates exactly one expense server-side (T-002), and flips the request
/// to `resolved`.
///
/// Requests come from [maintenanceQueueProvider] keyed to the **open** tab, so
/// the list is always scoped server-side via `for_user` and only the caller's
/// open requests appear. A request's photo (when [MaintenanceRequest.photoRef]
/// is a signed URL) renders as a small thumbnail. Every colour/spacing/radius/
/// font comes from the design tokens; numerals are localised via
/// [BanglaNumerals]. Reachable at `/maintenance`.
///
/// States: loading (spinner), error (retry → re-fetch), empty (friendly card),
/// data (the open-requests list). After a resolve the queue is refreshed (the
/// resolved request drops off the open tab) and the expense list is invalidated
/// so the new auto-expense shows on `/expenses`.
class MaintenanceQueueScreen extends ConsumerWidget {
  const MaintenanceQueueScreen({super.key, this.onResolve});

  /// Test seam: invoked with the entered [ResolveDraft] when the resolve dialog
  /// is confirmed. When null (the default, and what the router supplies) the
  /// screen runs the real resolve flow (auto-creates the expense) then refreshes.
  final Future<void> Function(ResolveDraft draft)? onResolve;

  static const String routePath = '/maintenance';
  static const String routeName = 'maintenance';

  /// The queue family key: the open tab (the landlord acts only on open
  /// requests; resolved ones live in the expense list as auto-expenses).
  static const MaintenanceStatus _openTab = MaintenanceStatus.open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final queueAsync = ref.watch(maintenanceQueueProvider(_openTab));

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.maintenance_title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: queueAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            l10n: l10n,
            onRetry: () => ref
                .read(maintenanceQueueProvider(_openTab).notifier)
                .refresh(),
          ),
          data: (requests) => _Body(
            requests: requests,
            onResolve: (request) => _openResolveDialog(context, ref, request),
          ),
        ),
      ),
    );
  }

  /// Opens the resolve-with-cost dialog for [request]; on confirm runs the
  /// resolve (auto-creates an expense), refreshes the queue, invalidates the
  /// expense list, and shows a confirmation snackbar. A failed resolve surfaces a
  /// friendly snackbar so a network blip never crashes the screen.
  Future<void> _openResolveDialog(
    BuildContext context,
    WidgetRef ref,
    MaintenanceRequest request,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<_ResolveResult>(
      context: context,
      builder: (_) => _ResolveDialog(requestId: request.id),
    );
    if (result == null) return;

    try {
      final draft = ResolveDraft(
        requestId: request.id,
        cost: result.cost,
        note: result.note,
      );
      if (onResolve != null) {
        await onResolve!(draft);
      } else {
        await ref
            .read(maintenanceRequestControllerProvider(request.id).notifier)
            .resolve(cost: draft.cost, note: draft.note);
      }
      // The resolved request drops off the open tab; the auto-expense lands on
      // the expense list — refresh the queue and invalidate the list so both
      // reflect the resolve on return.
      await ref.read(maintenanceQueueProvider(_openTab).notifier).refresh();
      ref.invalidate(expenseListProvider);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.maintenance_resolved)));
    } on ApiException {
      _reportError(messenger, l10n);
    } catch (_) {
      _reportError(messenger, l10n);
    }
  }

  void _reportError(ScaffoldMessengerState messenger, AppLocalizations l10n) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.maintenance_resolve_failed)),
      );
  }
}

/// The populated body: the open-count sub-line, the "New requests" heading and
/// the request cards (or the empty card).
class _Body extends StatelessWidget {
  const _Body({required this.requests, required this.onResolve});

  final List<MaintenanceRequest> requests;
  final ValueChanged<MaintenanceRequest> onResolve;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final open =
        requests.where((r) => r.status == MaintenanceStatus.open).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s5,
        KhatirSpacing.s4,
        KhatirSpacing.s5,
        KhatirSpacing.s6,
      ),
      children: [
        Text(
          l10n.maintenance_section_open,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: KhatirSpacing.s1),
        Text(
          l10n.maintenance_open_count(
            BanglaNumerals.format(open.length, localeCode),
          ),
          style: AppTextStyles.bodySmall.copyWith(
            color: KhatirColors.mutedDk,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: KhatirSpacing.s4),
        if (requests.isEmpty)
          _EmptyState(l10n: l10n)
        else
          for (final request in requests) ...[
            _RequestCard(
              key: ValueKey('maintenance-${request.id}'),
              request: request,
              onResolve: () => onResolve(request),
            ),
            const SizedBox(height: KhatirSpacing.s3),
          ],
      ],
    );
  }
}

/// One open-request card: the category emoji, the unit + category chip, the
/// description, an optional photo thumbnail, and the "Resolve + cost" action.
class _RequestCard extends StatelessWidget {
  const _RequestCard({
    super.key,
    required this.request,
    required this.onResolve,
  });

  final MaintenanceRequest request;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resolved = request.status == MaintenanceStatus.resolved;

    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _categoryEmoji(request.category),
            style: const TextStyle(fontSize: 26),
          ),
          const SizedBox(width: KhatirSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.maintenance_unit(
                          request.unitId.isEmpty ? '—' : request.unitId,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: KhatirSpacing.s2),
                    _CategoryChip(category: request.category),
                  ],
                ),
                if (request.description.isNotEmpty) ...[
                  const SizedBox(height: KhatirSpacing.s2),
                  Text(
                    request.description,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: KhatirColors.ink, height: 1.4),
                  ),
                ],
                if (request.photoRef.isNotEmpty) ...[
                  const SizedBox(height: KhatirSpacing.s3),
                  _Photo(url: request.photoRef),
                ],
                const SizedBox(height: KhatirSpacing.s3),
                if (resolved)
                  _ResolvedBadge(label: l10n.maintenance_resolved_badge)
                else
                  _ResolveButton(
                    key: ValueKey('maintenanceResolve-${request.id}'),
                    label: l10n.maintenance_resolve,
                    onPressed: onResolve,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A request photo, fetched from its signed URL ([MaintenanceRequest.photoRef]).
/// Renders inside a rounded clip; a failed/loading fetch degrades to a neutral
/// placeholder so a missing artefact never breaks the card.
class _Photo extends StatelessWidget {
  const _Photo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.md);
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _photoFallback(radius),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _photoFallback(radius),
      ),
    );
  }

  Widget _photoFallback(BorderRadius radius) => Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: KhatirColors.sageBg,
          borderRadius: radius,
        ),
        child: const Center(
          child: Icon(Icons.image_outlined, color: KhatirColors.sageDk),
        ),
      );
}

/// The rose category chip on a request card (matching the prototype's chip).
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final MaintenanceCategory category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s2,
        vertical: KhatirSpacing.s1 - 1,
      ),
      decoration: BoxDecoration(
        color: KhatirColors.roseBg,
        borderRadius: BorderRadius.circular(KhatirRadius.chip),
      ),
      child: Text(
        maintenanceCategoryLabel(l10n, category),
        style: AppTextStyles.bodySmall.copyWith(
          color: KhatirColors.roseDk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The "Resolve + cost" primary button on an open-request card.
class _ResolveButton extends StatelessWidget {
  const _ResolveButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.button);
    return Material(
      color: KhatirColors.sage,
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s4,
            vertical: KhatirSpacing.s2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded,
                  size: 16, color: KhatirColors.card),
              const SizedBox(width: KhatirSpacing.s2),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: KhatirColors.card,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A sage "Resolved" badge shown on a request that has already been resolved.
class _ResolvedBadge extends StatelessWidget {
  const _ResolvedBadge({required this.label});

  final String label;

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 14, color: KhatirColors.sageDk),
          const SizedBox(width: KhatirSpacing.s1),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: KhatirColors.sageDk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The value the resolve dialog returns on confirm — the entered cost and an
/// optional note.
class _ResolveResult {
  const _ResolveResult({required this.cost, this.note});

  final double cost;
  final String? note;
}

/// The resolve-with-cost dialog: a required cost field (becomes the auto-expense
/// amount) and an optional resolution note, with a hint that resolving records
/// an expense on the unit. Confirms with a [_ResolveResult]; cancels with null.
class _ResolveDialog extends StatefulWidget {
  const _ResolveDialog({required this.requestId});

  final String requestId;

  @override
  State<_ResolveDialog> createState() => _ResolveDialogState();
}

class _ResolveDialogState extends State<_ResolveDialog> {
  final _formKey = GlobalKey<FormState>();
  final _costCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _costCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final cost = double.parse(_costCtrl.text.trim());
    final note = _noteCtrl.text.trim();
    Navigator.of(context).pop(
      _ResolveResult(cost: cost, note: note.isEmpty ? null : note),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: KhatirColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      title: Text(
        l10n.maintenance_resolve_title,
        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.maintenance_resolve_hint,
              style:
                  AppTextStyles.bodySmall.copyWith(color: KhatirColors.mutedDk),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            _DialogField(
              key: const ValueKey('maintenanceCost'),
              controller: _costCtrl,
              label: l10n.maintenance_cost,
              hint: l10n.maintenance_cost_hint,
              icon: Icons.payments_outlined,
              keyboardType: const TextInputType.numberWithOptions(),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                final cost = double.tryParse((value ?? '').trim());
                if (cost == null || cost <= 0) {
                  return l10n.maintenance_err_cost;
                }
                return null;
              },
            ),
            const SizedBox(height: KhatirSpacing.s3),
            _DialogField(
              key: const ValueKey('maintenanceNote'),
              controller: _noteCtrl,
              label: l10n.maintenance_resolution_note,
              icon: Icons.notes_outlined,
              keyboardType: TextInputType.multiline,
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('maintenanceResolveCancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.maintenance_resolve_cancel,
            style: AppTextStyles.bodyMedium.copyWith(color: KhatirColors.mutedDk),
          ),
        ),
        FilledButton(
          key: const ValueKey('maintenanceResolveConfirm'),
          onPressed: _confirm,
          style: FilledButton.styleFrom(
            backgroundColor: KhatirColors.sage,
            foregroundColor: KhatirColors.cream,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KhatirRadius.button),
            ),
          ),
          child: Text(l10n.maintenance_resolve_confirm),
        ),
      ],
    );
  }
}

/// A single editable dialog field (white fill, line border, sage focus),
/// matching the shared form-field composition.
class _DialogField extends StatelessWidget {
  const _DialogField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.md);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: KhatirColors.mutedDk,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: AppTextStyles.bodySmall.copyWith(color: KhatirColors.muted),
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

/// Friendly empty-state card when there are no open maintenance requests.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s6),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔧', style: TextStyle(fontSize: 40)),
          const SizedBox(height: KhatirSpacing.s3),
          Text(
            l10n.maintenance_empty,
            textAlign: TextAlign.center,
            style:
                AppTextStyles.bodyMedium.copyWith(color: KhatirColors.mutedDk),
          ),
        ],
      ),
    );
  }
}

/// Error state: a friendly message and a retry button (reloads the queue).
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.l10n, required this.onRetry});

  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.button);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.common_network_error,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodyMedium.copyWith(color: KhatirColors.mutedDk),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            Material(
              color: KhatirColors.sage,
              borderRadius: radius,
              child: InkWell(
                onTap: onRetry,
                borderRadius: radius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KhatirSpacing.s6,
                    vertical: KhatirSpacing.s4,
                  ),
                  child: Text(
                    l10n.common_retry,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: KhatirColors.card,
                      fontWeight: FontWeight.w700,
                    ),
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

/// Localised display label for a [MaintenanceCategory].
String maintenanceCategoryLabel(
  AppLocalizations l10n,
  MaintenanceCategory category,
) =>
    switch (category) {
      MaintenanceCategory.plumbing => l10n.maintenance_category_plumbing,
      MaintenanceCategory.electrical => l10n.maintenance_category_electrical,
      MaintenanceCategory.paint => l10n.maintenance_category_paint,
      MaintenanceCategory.structural => l10n.maintenance_category_structural,
      MaintenanceCategory.appliance => l10n.maintenance_category_appliance,
      MaintenanceCategory.utility => l10n.maintenance_category_utility,
      MaintenanceCategory.other => l10n.maintenance_category_other,
    };

/// A decorative category emoji, matching the prototype's per-request icons.
String _categoryEmoji(MaintenanceCategory category) => switch (category) {
      MaintenanceCategory.plumbing => '🚿',
      MaintenanceCategory.electrical => '💡',
      MaintenanceCategory.paint => '🎨',
      MaintenanceCategory.structural => '🏗️',
      MaintenanceCategory.appliance => '❄️',
      MaintenanceCategory.utility => '💧',
      MaintenanceCategory.other => '🔧',
    };
