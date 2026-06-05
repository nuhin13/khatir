import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/i18n/bangla_numerals.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/maintenance_enums.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../screens/expenses_screen.dart';
import '../screens/maintenance_queue_screen.dart';

/// A lightweight maintenance + expense summary for the unit-detail screen
/// (EPIC-08 T-011). Two soft cards, top to bottom:
///
/// * **Maintenance** — the open-request count plus the most recent request
///   lines (category + description), with a "View all" link to the maintenance
///   queue (`/maintenance`, T-010).
/// * **Expenses** — the total of the recent expenses plus their count and the
///   most recent rows (category + amount), with a "View all" link to the
///   expenses list (`/expenses`, T-008).
///
/// Both cards read unit-scoped providers ([unitMaintenanceProvider] /
/// [unitExpensesProvider]), each keyed by [unitId] and scoped server-side via
/// `for_user` + `?unit=<id>`, so a unit only ever shows its owner's data. Each
/// card renders its own loading / empty / error / data state independently, so a
/// slow or failed expense fetch never blocks the maintenance card. The full
/// lists live on their own screens; this is only a summary. Every
/// colour/spacing/radius/font comes from the design tokens; numerals are
/// localised via [BanglaNumerals].
class UnitMaintExpenseSection extends ConsumerWidget {
  const UnitMaintExpenseSection({required this.unitId, super.key});

  /// The unit whose maintenance + expenses are summarised.
  final String unitId;

  /// How many recent items each card lists before the "View all" link.
  static const int _maxItems = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final maintenanceAsync = ref.watch(unitMaintenanceProvider(unitId));
    final expensesAsync = ref.watch(unitExpensesProvider(unitId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          key: const ValueKey('unitMaintenanceCard'),
          title: l10n.unit_maintenance,
          onViewAll: () =>
              GoRouter.of(context).pushNamed(MaintenanceQueueScreen.routeName),
          child: maintenanceAsync.when(
            loading: () => const _SectionLoading(),
            error: (_, _) => _SectionMessage(text: l10n.unit_section_error),
            data: (requests) => _MaintenanceBody(
              requests: requests,
              maxItems: _maxItems,
              localeCode: localeCode,
            ),
          ),
        ),
        const SizedBox(height: KhatirSpacing.s3),
        _SectionCard(
          key: const ValueKey('unitExpensesCard'),
          title: l10n.unit_expenses,
          onViewAll: () =>
              GoRouter.of(context).pushNamed(ExpensesScreen.routeName),
          child: expensesAsync.when(
            loading: () => const _SectionLoading(),
            error: (_, _) => _SectionMessage(text: l10n.unit_section_error),
            data: (expenses) => _ExpensesBody(
              expenses: expenses,
              maxItems: _maxItems,
              localeCode: localeCode,
            ),
          ),
        ),
      ],
    );
  }
}

/// A soft card with a heading row (title + "View all" link) and an arbitrary
/// [child] body (the loading / empty / data content).
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.title,
    required this.onViewAll,
    required this.child,
  });

  final String title;
  final VoidCallback onViewAll;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _ViewAllLink(label: l10n.unit_view_all, onTap: onViewAll),
            ],
          ),
          const SizedBox(height: KhatirSpacing.s3),
          child,
        ],
      ),
    );
  }
}

/// The "View all" link in a section heading — a sage text label with a trailing
/// chevron, routing to the full list screen.
class _ViewAllLink extends StatelessWidget {
  const _ViewAllLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.chip);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s2,
            vertical: KhatirSpacing.s1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: KhatirColors.sageDk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: KhatirColors.sageDk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The maintenance card body: an open-count sub-line, then the most recent
/// requests (or the empty line). Capped at [maxItems] rows.
class _MaintenanceBody extends StatelessWidget {
  const _MaintenanceBody({
    required this.requests,
    required this.maxItems,
    required this.localeCode,
  });

  final List<MaintenanceRequest> requests;
  final int maxItems;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (requests.isEmpty) {
      return _SectionMessage(text: l10n.unit_maint_empty);
    }
    final openCount =
        requests.where((r) => r.status == MaintenanceStatus.open).length;
    final recent = requests.take(maxItems).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.unit_maint_open_count(
            BanglaNumerals.format(openCount, localeCode),
          ),
          style: AppTextStyles.bodySmall.copyWith(
            color: KhatirColors.mutedDk,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: KhatirSpacing.s3),
        for (var i = 0; i < recent.length; i++) ...[
          if (i > 0) const SizedBox(height: KhatirSpacing.s2),
          _MaintenanceRow(request: recent[i]),
        ],
      ],
    );
  }
}

/// One recent maintenance row: category emoji + label, the description, and a
/// status chip.
class _MaintenanceRow extends StatelessWidget {
  const _MaintenanceRow({required this.request});

  final MaintenanceRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _maintenanceEmoji(request.category),
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(width: KhatirSpacing.s2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                maintenanceCategoryLabel(l10n, request.category),
                style: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              if (request.description.isNotEmpty)
                Text(
                  request.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: KhatirColors.mutedDk),
                ),
            ],
          ),
        ),
        const SizedBox(width: KhatirSpacing.s2),
        _StatusChip(status: request.status),
      ],
    );
  }
}

/// A small status chip for a maintenance request (sage when resolved, rose
/// otherwise — i.e. still open / awaiting action).
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final MaintenanceStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resolved = status == MaintenanceStatus.resolved;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s2,
        vertical: KhatirSpacing.s1 - 1,
      ),
      decoration: BoxDecoration(
        color: resolved ? KhatirColors.sageBg : KhatirColors.roseBg,
        borderRadius: BorderRadius.circular(KhatirRadius.chip),
      ),
      child: Text(
        resolved
            ? l10n.maintenance_resolved_badge
            : l10n.unit_maint_status_open,
        style: AppTextStyles.bodySmall.copyWith(
          color: resolved ? KhatirColors.sageDk : KhatirColors.roseDk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The expense card body: a total + count sub-line, then the most recent
/// expenses (or the empty line). Capped at [maxItems] rows.
class _ExpensesBody extends StatelessWidget {
  const _ExpensesBody({
    required this.expenses,
    required this.maxItems,
    required this.localeCode,
  });

  final List<Expense> expenses;
  final int maxItems;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (expenses.isEmpty) {
      return _SectionMessage(text: l10n.unit_expenses_empty);
    }
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final recent = expenses.take(maxItems).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              l10n.unit_expenses_total(
                BanglaNumerals.format(total.round(), localeCode),
              ),
              style: AppTextStyles.titleMedium.copyWith(
                color: KhatirColors.roseDk,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: KhatirSpacing.s2),
            Text(
              l10n.unit_expenses_count(
                BanglaNumerals.format(expenses.length, localeCode),
              ),
              style: AppTextStyles.bodySmall.copyWith(
                color: KhatirColors.mutedDk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: KhatirSpacing.s3),
        for (var i = 0; i < recent.length; i++) ...[
          if (i > 0) const SizedBox(height: KhatirSpacing.s2),
          _ExpenseRow(expense: recent[i], localeCode: localeCode),
        ],
      ],
    );
  }
}

/// One recent expense row: category emoji + label on the left, the rose amount
/// on the right.
class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense, required this.localeCode});

  final Expense expense;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Text(
          _expenseEmoji(expense.category),
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(width: KhatirSpacing.s2),
        Expanded(
          child: Text(
            categoryLabel(l10n, expense.category),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: KhatirSpacing.s2),
        Text(
          l10n.unit_expenses_total(
            BanglaNumerals.format(expense.amount.round(), localeCode),
          ),
          style: AppTextStyles.bodySmall.copyWith(
            color: KhatirColors.roseDk,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// A short inline loading row (a small spinner) for a section card body.
class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: KhatirSpacing.s2),
      child: SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

/// A muted single-line message for a section body (empty / error states).
class _SectionMessage extends StatelessWidget {
  const _SectionMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.mutedDk),
    );
  }
}

/// A decorative category emoji for a maintenance request, matching the queue
/// screen's per-request icons.
String _maintenanceEmoji(MaintenanceCategory category) => switch (category) {
      MaintenanceCategory.plumbing => '🚿',
      MaintenanceCategory.electrical => '💡',
      MaintenanceCategory.paint => '🎨',
      MaintenanceCategory.structural => '🏗️',
      MaintenanceCategory.appliance => '❄️',
      MaintenanceCategory.utility => '💧',
      MaintenanceCategory.other => '🔧',
    };

/// A decorative category emoji for an expense, matching the expenses screen's
/// per-row icons.
String _expenseEmoji(ExpenseCategory category) => switch (category) {
      ExpenseCategory.plumbing => '🔧',
      ExpenseCategory.paint => '🎨',
      ExpenseCategory.electrical => '💡',
      ExpenseCategory.structural => '🏗️',
      ExpenseCategory.appliance => '❄️',
      ExpenseCategory.utility => '💧',
      ExpenseCategory.other => '✨',
    };
