import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/i18n/bangla_numerals.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/charts/k_bar_chart.dart';
import '../../../../core/widgets/charts/k_donut_chart.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../maintenance/data/models/maintenance_enums.dart';
import '../../../maintenance/presentation/screens/expenses_screen.dart'
    show categoryLabel;
import '../../data/dashboard_model.dart';
import '../../data/dashboard_providers.dart';

/// The landlord **Dashboard / charts** screen (EPIC-09 T-006), per the
/// `dashboard` prototype (`proto/screens-landlord2.js` → `reg('dashboard')`):
/// an ink income hero, a 6-month collection-rate bar chart, an occupancy donut
/// with a colour legend, an income-vs-expense trend line, the top expense
/// categories, and a late-payers card whose quick-request CTA routes to
/// `/rent/request`.
///
/// Every metric comes from one `GET /dashboard` read via [dashboardProvider]
/// (owner-scoped + cached server-side), so the screen never fans out a request
/// per card. Colours/spacing/radii/fonts all come from the shared design
/// tokens; numerals are localised via [BanglaNumerals].
///
/// States: loading (the charts show their own shimmer), error (retry → re-fetch),
/// empty (a brand-new landlord with no units/rent/expense → a friendly card),
/// data (the full layout). Reachable at `/landlord/dashboard` (the Charts tab).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, this.onLatePayerRequest});

  /// Test seam: invoked instead of routing to `/rent/request` when the
  /// late-payers quick-request CTA is tapped. When null (the default, and what
  /// the router supplies) the real navigation runs.
  final VoidCallback? onLatePayerRequest;

  static const String routePath = '/landlord/dashboard';
  static const String routeName = 'landlordDashboard';

  /// The dashboard window key (null = the server's configured default).
  static const int? _window = null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(dashboardProvider(_window));

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.dashboard_title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: async.when(
          loading: () => _DashboardBody(
            data: const DashboardData(),
            isLoading: true,
            onLatePayerRequest: () => _request(context),
          ),
          error: (_, _) => _ErrorState(
            l10n: l10n,
            onRetry: () =>
                ref.read(dashboardProvider(_window).notifier).refresh(),
          ),
          data: (data) {
            if (_isEmpty(data)) {
              return _EmptyState(l10n: l10n);
            }
            return _DashboardBody(
              data: data,
              isLoading: false,
              onLatePayerRequest: () => _request(context),
            );
          },
        ),
      ),
    );
  }

  /// A brand-new landlord has nothing to chart: no units, no money in or out,
  /// and no trend points.
  static bool _isEmpty(DashboardData d) =>
      d.totalUnits == 0 &&
      d.totalIncome == 0 &&
      d.totalExpense == 0 &&
      d.totalCollected == 0 &&
      d.monthlySeries.isEmpty &&
      d.topExpenseCategories.isEmpty;

  void _request(BuildContext context) {
    final onRequest = onLatePayerRequest;
    if (onRequest != null) {
      onRequest();
      return;
    }
    context.push('/rent/request');
  }
}

/// The populated dashboard layout. When [isLoading] is true the charts render
/// their own loading placeholders and the cards show zeroed figures, so the
/// scaffold never collapses while the first read is in flight.
class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.data,
    required this.isLoading,
    required this.onLatePayerRequest,
  });

  final DashboardData data;
  final bool isLoading;
  final VoidCallback onLatePayerRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s5,
        KhatirSpacing.s4,
        KhatirSpacing.s5,
        KhatirSpacing.s6,
      ),
      children: [
        _IncomeHero(
          income: data.totalIncome,
          localeCode: localeCode,
          l10n: l10n,
        ),
        const SizedBox(height: KhatirSpacing.s4),
        _Section(label: l10n.dashboard_collection),
        const SizedBox(height: KhatirSpacing.s2),
        _CollectionChartCard(
          series: data.monthlySeries,
          localeCode: localeCode,
          isLoading: isLoading,
          l10n: l10n,
        ),
        const SizedBox(height: KhatirSpacing.s4),
        _Section(label: l10n.dashboard_occupancy),
        const SizedBox(height: KhatirSpacing.s2),
        _OccupancyCard(
          data: data,
          localeCode: localeCode,
          isLoading: isLoading,
          l10n: l10n,
        ),
        const SizedBox(height: KhatirSpacing.s4),
        _Section(label: l10n.dashboard_income_expense),
        const SizedBox(height: KhatirSpacing.s2),
        _IncomeExpenseCard(
          series: data.monthlySeries,
          localeCode: localeCode,
          isLoading: isLoading,
          l10n: l10n,
        ),
        const SizedBox(height: KhatirSpacing.s4),
        _Section(label: l10n.dashboard_expenses),
        const SizedBox(height: KhatirSpacing.s2),
        _TopExpenses(
          categories: data.topExpenseCategories,
          localeCode: localeCode,
          l10n: l10n,
        ),
        const SizedBox(height: KhatirSpacing.s4),
        _LatePayersCard(
          count: data.latePayerCount,
          localeCode: localeCode,
          l10n: l10n,
          onRequest: onLatePayerRequest,
        ),
      ],
    );
  }
}

/// The ink-gradient income hero card mirroring the prototype's top card.
class _IncomeHero extends StatelessWidget {
  const _IncomeHero({
    required this.income,
    required this.localeCode,
    required this.l10n,
  });

  final double income;
  final String localeCode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('dashboardIncomeCard'),
      padding: const EdgeInsets.all(KhatirSpacing.s5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KhatirColors.ink, KhatirColors.ink2],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboard_income,
            style: AppTextStyles.bodySmall.copyWith(
              color: KhatirColors.card.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: KhatirSpacing.s1),
          Text(
            l10n.dashboard_amount(
              BanglaNumerals.format(income.round(), localeCode),
            ),
            key: const ValueKey('dashboardIncomeAmount'),
            style: AppTextStyles.displayLarge.copyWith(
              color: KhatirColors.card,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// A section heading above a chart/card block.
class _Section extends StatelessWidget {
  const _Section({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

/// A plain white card wrapper used by the chart blocks.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: child,
    );
  }
}

/// The 6-month collection-rate bar chart card. The series is mapped to one bar
/// per month: each bar's value is that month's collection rate
/// (`collected / (collected + outstanding)` is unavailable client-side, so we
/// show the collected share of the busiest month) — actually we render the raw
/// collected amount as a percentage of the window's peak so the bars stay
/// comparable, matching the prototype's relative-height bars.
class _CollectionChartCard extends StatelessWidget {
  const _CollectionChartCard({
    required this.series,
    required this.localeCode,
    required this.isLoading,
    required this.l10n,
  });

  final List<MonthPoint> series;
  final String localeCode;
  final bool isLoading;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final peak = series.fold<double>(
      0,
      (max, p) => p.collected > max ? p.collected : max,
    );
    final bars = [
      for (final p in series)
        KBarDatum(
          label: _monthLabel(p.period, localeCode),
          // Each bar as a % of the peak month so heights stay comparable.
          value: peak <= 0 ? 0 : (p.collected / peak * 100),
        ),
    ];
    return _ChartCard(
      key: const ValueKey('dashboardCollectionChart'),
      child: KBarChart(
        data: bars,
        localeCode: localeCode,
        maxValue: 100,
        valueSuffix: '%',
        isLoading: isLoading,
        emptyLabel: l10n.dashboard_chart_empty,
      ),
    );
  }
}

/// The occupancy donut + colour legend (occupied / vacant), mirroring the
/// prototype's ring + side legend.
class _OccupancyCard extends StatelessWidget {
  const _OccupancyCard({
    required this.data,
    required this.localeCode,
    required this.isLoading,
    required this.l10n,
  });

  final DashboardData data;
  final String localeCode;
  final bool isLoading;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final occupied = data.occupiedUnits;
    final total = data.totalUnits;
    final vacant = (total - occupied).clamp(0, total).toInt();
    // Prefer the server's occupancy_rate (0..1) so the ring matches the backend
    // rounding; fall back to the count ratio if the rate is absent.
    final percent = data.occupancyRate > 0
        ? data.occupancyRate * 100
        : (total <= 0 ? 0.0 : occupied / total * 100);
    String fmt(int v) => BanglaNumerals.format(v, localeCode, grouped: false);

    return _ChartCard(
      key: const ValueKey('dashboardOccupancyCard'),
      child: Row(
        children: [
          KDonutChart.percentage(
            key: const ValueKey('dashboardOccupancyDonut'),
            percent: percent,
            localeCode: localeCode,
            centerSublabel: l10n.dashboard_occupancy_units(
              fmt(occupied),
              fmt(total),
            ),
            isLoading: isLoading,
            emptyLabel: l10n.dashboard_chart_empty,
          ),
          const SizedBox(width: KhatirSpacing.s4),
          Expanded(
            child: Column(
              children: [
                _LegendRow(
                  color: KhatirColors.sage,
                  label: l10n.dashboard_occupied,
                  value: fmt(occupied),
                ),
                _LegendRow(
                  color: KhatirColors.rose,
                  label: l10n.dashboard_vacant,
                  value: fmt(vacant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One coloured-dot legend row inside the occupancy card.
class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s1 * 0.75),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: KhatirSpacing.s2),
          Expanded(
            child: Text(
              label,
              style:
                  AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
              fontFamily: KhatirFonts.title,
            ),
          ),
        ],
      ),
    );
  }
}

/// Number of trailing months charted in the income-vs-expense view.
const int _incomeExpenseWindow = 6;

/// The income-vs-expense card (EPIC-09 T-009): a grouped two-series bar chart —
/// for each month a sage **income** rod ([MonthPoint.collected]) beside a rose
/// **expense** rod ([MonthPoint.expense]) — over the trailing 6-month window,
/// with a sage/rose series legend below.
///
/// Both rods share one axis maximum (the peak of either series across the
/// window) so income and expense stay visually comparable. When every month is
/// zero for both series the [KBarChart] shows its own empty state.
class _IncomeExpenseCard extends StatelessWidget {
  const _IncomeExpenseCard({
    required this.series,
    required this.localeCode,
    required this.isLoading,
    required this.l10n,
  });

  final List<MonthPoint> series;
  final String localeCode;
  final bool isLoading;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Trailing 6-month window (the series arrives oldest → newest).
    final window = series.length > _incomeExpenseWindow
        ? series.sublist(series.length - _incomeExpenseWindow)
        : series;
    // Treat an all-zero window as empty so the chart shows its empty state
    // rather than a row of flat, height-zero bars.
    final hasData = window.any((p) => p.collected > 0 || p.expense > 0);
    final bars = [
      if (hasData)
        for (final p in window)
          KBarDatum(
            label: _monthLabel(p.period, localeCode),
            value: p.collected,
            secondValue: p.expense,
          ),
    ];
    return _ChartCard(
      key: const ValueKey('dashboardIncomeExpenseChart'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KBarChart(
            data: bars,
            localeCode: localeCode,
            isLoading: isLoading,
            emptyLabel: l10n.dashboard_chart_empty,
          ),
          const SizedBox(height: KhatirSpacing.s3),
          Row(
            children: [
              _LegendDot(
                color: KhatirColors.sage,
                label: l10n.dashboard_income_series,
              ),
              const SizedBox(width: KhatirSpacing.s4),
              _LegendDot(
                color: KhatirColors.rose,
                label: l10n.dashboard_expense_series,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small inline coloured-dot + label used by the income/expense legend.
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: KhatirSpacing.s2),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.mutedDk),
        ),
      ],
    );
  }
}

/// The top expense categories list: one soft rose row per category with a
/// proportional progress bar (relative to the largest category) and the amount.
class _TopExpenses extends StatelessWidget {
  const _TopExpenses({
    required this.categories,
    required this.localeCode,
    required this.l10n,
  });

  final List<CategoryTotal> categories;
  final String localeCode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return _ChartCard(
        key: const ValueKey('dashboardTopExpensesEmpty'),
        child: Center(
          child: Text(
            l10n.dashboard_chart_empty,
            style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.muted),
          ),
        ),
      );
    }
    final peak = categories.fold<double>(
      0,
      (max, c) => c.amount > max ? c.amount : max,
    );
    return Column(
      key: const ValueKey('dashboardTopExpenses'),
      children: [
        for (final c in categories) ...[
          _ExpenseRow(
            category: c.category,
            amount: c.amount,
            fraction: peak <= 0 ? 0 : c.amount / peak,
            localeCode: localeCode,
            l10n: l10n,
          ),
          const SizedBox(height: KhatirSpacing.s2),
        ],
      ],
    );
  }
}

/// One top-expense-category row.
class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.category,
    required this.amount,
    required this.fraction,
    required this.localeCode,
    required this.l10n,
  });

  final ExpenseCategory category;
  final double amount;
  final double fraction;
  final String localeCode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('dashboardExpense-${category.name}'),
      padding: const EdgeInsets.all(KhatirSpacing.s3),
      decoration: BoxDecoration(
        color: KhatirColors.roseBg,
        borderRadius: BorderRadius.circular(KhatirRadius.tile),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryLabel(l10n, category),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFamily: KhatirFonts.title,
                  ),
                ),
                const SizedBox(height: KhatirSpacing.s1),
                ClipRRect(
                  borderRadius: BorderRadius.circular(KhatirRadius.pill),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: KhatirColors.card,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      KhatirColors.roseDk,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KhatirSpacing.s3),
          Text(
            l10n.dashboard_amount(
              BanglaNumerals.format(amount.round(), localeCode),
            ),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
              fontFamily: KhatirFonts.title,
              color: KhatirColors.roseDk,
            ),
          ),
        ],
      ),
    );
  }
}

/// The late-payers card: the count of overdue tenants and, when any are late, a
/// quick-request CTA that routes to `/rent/request` (per the task navigation).
class _LatePayersCard extends StatelessWidget {
  const _LatePayersCard({
    required this.count,
    required this.localeCode,
    required this.l10n,
    required this.onRequest,
  });

  final int count;
  final String localeCode;
  final AppLocalizations l10n;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final hasLate = count > 0;
    return Container(
      key: const ValueKey('dashboardLatePayers'),
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: hasLate ? KhatirColors.roseBg : KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboard_late,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: hasLate ? KhatirColors.roseDk : KhatirColors.sageDk,
            ),
          ),
          const SizedBox(height: KhatirSpacing.s1),
          Text(
            hasLate
                ? l10n.dashboard_late_count(
                    BanglaNumerals.format(count, localeCode, grouped: false),
                  )
                : l10n.dashboard_late_none,
            style: AppTextStyles.bodyMedium.copyWith(color: KhatirColors.mutedDk),
          ),
          if (hasLate) ...[
            const SizedBox(height: KhatirSpacing.s3),
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: KhatirColors.rose,
                borderRadius: BorderRadius.circular(KhatirRadius.button),
                child: InkWell(
                  key: const ValueKey('dashboardLateRequest'),
                  onTap: onRequest,
                  borderRadius: BorderRadius.circular(KhatirRadius.button),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KhatirSpacing.s5,
                      vertical: KhatirSpacing.s3,
                    ),
                    child: Text(
                      l10n.dashboard_late_request,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: KhatirColors.card,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Whole-screen empty state for a brand-new landlord with nothing to chart.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Column(
          key: const ValueKey('dashboardEmpty'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 44)),
            const SizedBox(height: KhatirSpacing.s3),
            Text(
              l10n.dashboard_empty,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodyMedium.copyWith(color: KhatirColors.mutedDk),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state: a friendly message and a retry button (reloads `/dashboard`).
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
                key: const ValueKey('dashboardRetry'),
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

/// Derives a short axis label from a `YYYY-MM` period string. Falls back to the
/// raw month number (localised) when the period is malformed/empty so the chart
/// never shows a blank axis.
String _monthLabel(String period, String localeCode) {
  final parts = period.split('-');
  if (parts.length < 2) return period;
  final month = int.tryParse(parts[1]);
  if (month == null || month < 1 || month > 12) return period;
  final names = localeCode == 'bn' ? _bnMonths : _enMonths;
  return names[month - 1];
}

const List<String> _enMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _bnMonths = [
  'জানু',
  'ফেব',
  'মার্চ',
  'এপ্রি',
  'মে',
  'জুন',
  'জুলা',
  'আগ',
  'সেপ্টে',
  'অক্টো',
  'নভে',
  'ডিসে',
];
