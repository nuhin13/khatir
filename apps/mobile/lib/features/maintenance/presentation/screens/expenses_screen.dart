import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/i18n/bangla_numerals.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../properties/data/models/building.dart';
import '../../../properties/data/properties_providers.dart';
import '../../data/expense_csv_sharer.dart';
import '../../data/expense_repository.dart';
import '../../data/models/maintenance_enums.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';

/// The landlord's maintenance & expenses list (EPIC-08 T-008), per the
/// `expenses` prototype (`proto/screens-landlord2.js` → `reg('expenses')`): a
/// butter total-expenses hero, an optional building filter row, then the
/// "Recent expenses" list. The app-bar carries the **Add expense** action
/// (→ `/expenses/add`) and an **Export CSV** action that shares the scoped +
/// filtered expenses as a CSV file.
///
/// Both manually-logged ([ExpenseSource.manual]) and maintenance-sourced
/// ([ExpenseSource.request]) expenses appear, each tagged with a source chip
/// (per the task notes). The list is loaded via [expenseListProvider], keyed by
/// the selected [ExpenseFilter] (a building filter here), so it is always
/// scoped server-side via `for_user` and the export can never leak another
/// user's rows. Every colour/spacing/radius/font comes from the design tokens;
/// numerals are localised via [BanglaNumerals].
///
/// States: loading (spinner), error (retry → re-fetch), empty (friendly card),
/// data (the total hero + filter + list). Reachable at `/expenses`.
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key, this.onAdd});

  /// Test seam: invoked instead of routing to `/expenses/add` when the Add
  /// action is tapped. When null (the default, and what the router supplies) the
  /// real navigation runs.
  final VoidCallback? onAdd;

  static const String routePath = '/expenses';
  static const String routeName = 'expenses';

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  /// The currently-selected building filter (null = all buildings).
  String? _buildingId;

  /// The current [ExpenseFilter], held as a single stable instance so the
  /// [expenseListProvider] family key does not change on every rebuild.
  /// [ExpenseFilter] has no value equality, so re-deriving it inside `build`
  /// would spawn a fresh family member each frame and never settle; instead it
  /// is rebuilt only when the selected building actually changes.
  ExpenseFilter? _filter;

  void _selectBuilding(String? id) {
    if (id == _buildingId) return;
    setState(() {
      _buildingId = id;
      _filter = id == null ? null : ExpenseFilter(buildingId: id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final expensesAsync = ref.watch(expenseListProvider(_filter));

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.expenses_title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            key: const ValueKey('expensesExport'),
            tooltip: l10n.expenses_export,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => _export(context),
          ),
          IconButton(
            key: const ValueKey('expensesAdd'),
            tooltip: l10n.expenses_add,
            icon: const Icon(Icons.add_rounded),
            onPressed: _add,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: expensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            l10n: l10n,
            onRetry: () =>
                ref.read(expenseListProvider(_filter).notifier).refresh(),
          ),
          data: (expenses) => _Body(
            expenses: expenses,
            selectedBuildingId: _buildingId,
            onBuildingSelected: _selectBuilding,
          ),
        ),
      ),
    );
  }

  void _add() {
    final onAdd = widget.onAdd;
    if (onAdd != null) {
      onAdd();
      return;
    }
    context.push('/expenses/add');
  }

  /// Fetches the (scoped + filtered) expenses as CSV and hands them to the OS
  /// share sheet. A failed fetch/share surfaces a friendly snackbar so a missing
  /// share target / network blip never crashes the screen.
  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final csv =
          await ref.read(expenseRepositoryProvider).exportCsv(filter: _filter);
      await ref
          .read(expenseCsvSharerProvider)
          .shareCsv(csv: csv, fileName: 'expenses.csv');
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.expenses_export_failed)));
    }
  }
}

/// The populated body: the total-expenses hero, the building filter row, the
/// "Recent expenses" heading and the list (or the empty card).
class _Body extends ConsumerWidget {
  const _Body({
    required this.expenses,
    required this.selectedBuildingId,
    required this.onBuildingSelected,
  });

  final List<Expense> expenses;
  final String? selectedBuildingId;
  final ValueChanged<String?> onBuildingSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s5,
        KhatirSpacing.s4,
        KhatirSpacing.s5,
        KhatirSpacing.s6,
      ),
      children: [
        _TotalHero(
          total: total,
          count: expenses.length,
          localeCode: localeCode,
          l10n: l10n,
        ),
        const SizedBox(height: KhatirSpacing.s4),
        _BuildingFilter(
          selectedBuildingId: selectedBuildingId,
          onSelected: onBuildingSelected,
        ),
        const SizedBox(height: KhatirSpacing.s4),
        Text(
          l10n.expenses_section_recent,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: KhatirSpacing.s3),
        if (expenses.isEmpty)
          _EmptyState(l10n: l10n)
        else
          _ExpenseList(expenses: expenses),
      ],
    );
  }
}

/// The butter-gradient "Total expenses" hero card: the month chip, the label,
/// the big total figure, and the count sub-line.
class _TotalHero extends StatelessWidget {
  const _TotalHero({
    required this.total,
    required this.count,
    required this.localeCode,
    required this.l10n,
  });

  final double total;
  final int count;
  final String localeCode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('expensesTotalCard'),
      padding: const EdgeInsets.all(KhatirSpacing.s5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KhatirColors.butter, KhatirColors.butterDk],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthChip(label: l10n.expenses_this_month),
          const SizedBox(height: KhatirSpacing.s2),
          Text(
            l10n.expenses_total,
            style: AppTextStyles.bodyMedium.copyWith(color: KhatirColors.ink),
          ),
          const SizedBox(height: KhatirSpacing.s1),
          Text(
            l10n.expenses_total_amount(
              BanglaNumerals.format(total.round(), localeCode),
            ),
            key: const ValueKey('expensesTotalAmount'),
            style: AppTextStyles.displayLarge.copyWith(
              color: KhatirColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: KhatirSpacing.s1),
          Text(
            l10n.expenses_count(BanglaNumerals.format(count, localeCode)),
            style: AppTextStyles.bodySmall.copyWith(
              color: KhatirColors.mutedDk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The translucent "This month" pill on the hero card.
class _MonthChip extends StatelessWidget {
  const _MonthChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s3,
        vertical: KhatirSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: KhatirColors.card.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(KhatirRadius.chip),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: KhatirColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The horizontal building filter row — an "All" chip plus one chip per
/// building, driving the [ExpenseFilter.buildingId]. Buildings are read via
/// [buildingsProvider]; while they load (or if the read fails) only the "All"
/// chip shows, so the filter never blocks the list.
class _BuildingFilter extends ConsumerWidget {
  const _BuildingFilter({
    required this.selectedBuildingId,
    required this.onSelected,
  });

  final String? selectedBuildingId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final buildings =
        ref.watch(buildingsProvider).asData?.value ?? const <Building>[];

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            key: const ValueKey('expensesFilter-all'),
            label: l10n.expenses_filter_all,
            selected: selectedBuildingId == null,
            onTap: () => onSelected(null),
          ),
          for (final building in buildings) ...[
            const SizedBox(width: KhatirSpacing.s2),
            _FilterChip(
              key: ValueKey('expensesFilter-${building.id}'),
              label: building.name,
              selected: selectedBuildingId == building.id,
              onTap: () => onSelected(building.id),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single sage-tinted filter pill; the selected one fills sage.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.chip);
    return Material(
      color: selected ? KhatirColors.sage : KhatirColors.sageBg,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s4,
            vertical: KhatirSpacing.s2,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? KhatirColors.card : KhatirColors.sageDk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The "Recent expenses" list — a single white card of [_ExpenseRow]s divided
/// by hairlines, mirroring the prototype's grouped `fieldrow` card.
class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < expenses.length; i++) ...[
            _ExpenseRow(
              key: ValueKey('expense-${expenses[i].id}'),
              expense: expenses[i],
            ),
            if (i < expenses.length - 1)
              const Divider(height: 1, thickness: 1, color: KhatirColors.line),
          ],
        ],
      ),
    );
  }
}

/// One expense row: a leading category emoji, the category + source chip + date,
/// and the trailing rose amount.
class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({super.key, required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _categoryEmoji(expense.category),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: KhatirSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        categoryLabel(l10n, expense.category),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: KhatirSpacing.s2),
                    _SourceChip(source: expense.source),
                  ],
                ),
                const SizedBox(height: KhatirSpacing.s1),
                Text(
                  _formatDate(context, expense.date, localeCode),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: KhatirColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: KhatirSpacing.s3),
          Text(
            l10n.expenses_amount(
              BanglaNumerals.format(expense.amount.round(), localeCode),
            ),
            style: AppTextStyles.bodyMedium.copyWith(
              color: KhatirColors.roseDk,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(
    BuildContext context,
    DateTime? date,
    String localeCode,
  ) {
    if (date == null) return AppLocalizations.of(context).receipt_dash;
    String part(int v, {bool pad = false}) {
      final s = BanglaNumerals.format(v, localeCode, grouped: false);
      return pad ? s.padLeft(2, '0') : s;
    }

    return '${part(date.year)}-${part(date.month, pad: true)}-'
        '${part(date.day, pad: true)}';
  }
}

/// A small source pill distinguishing a manually-logged expense from one
/// auto-created by resolving a maintenance request (sage for manual, butter for
/// maintenance), per the task notes.
class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});

  final ExpenseSource source;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRequest = source == ExpenseSource.request;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s2,
        vertical: KhatirSpacing.s1 - 1,
      ),
      decoration: BoxDecoration(
        color: isRequest ? KhatirColors.butterBg : KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.chip),
      ),
      child: Text(
        isRequest ? l10n.expenses_source_request : l10n.expenses_source_manual,
        style: AppTextStyles.bodySmall.copyWith(
          color: isRequest ? KhatirColors.butterDk : KhatirColors.sageDk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Friendly empty-state card when no expenses are in view.
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
          const Text('🧾', style: TextStyle(fontSize: 40)),
          const SizedBox(height: KhatirSpacing.s3),
          Text(
            l10n.expenses_empty,
            textAlign: TextAlign.center,
            style:
                AppTextStyles.bodyMedium.copyWith(color: KhatirColors.mutedDk),
          ),
        ],
      ),
    );
  }
}

/// Error state: a friendly message and a retry button (reloads `/expenses`).
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

/// Localised display label for an [ExpenseCategory].
String categoryLabel(AppLocalizations l10n, ExpenseCategory category) =>
    switch (category) {
      ExpenseCategory.plumbing => l10n.expenses_category_plumbing,
      ExpenseCategory.paint => l10n.expenses_category_paint,
      ExpenseCategory.electrical => l10n.expenses_category_electrical,
      ExpenseCategory.structural => l10n.expenses_category_structural,
      ExpenseCategory.appliance => l10n.expenses_category_appliance,
      ExpenseCategory.utility => l10n.expenses_category_utility,
      ExpenseCategory.other => l10n.expenses_category_other,
    };

/// A decorative category emoji, matching the prototype's per-row icons.
String _categoryEmoji(ExpenseCategory category) => switch (category) {
      ExpenseCategory.plumbing => '🔧',
      ExpenseCategory.paint => '🎨',
      ExpenseCategory.electrical => '💡',
      ExpenseCategory.structural => '🏗️',
      ExpenseCategory.appliance => '❄️',
      ExpenseCategory.utility => '💧',
      ExpenseCategory.other => '✨',
    };
