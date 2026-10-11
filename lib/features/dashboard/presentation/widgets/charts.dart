import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/common.dart';
import '../../../transactions/domain/finance_calculator.dart';
import '../../../transactions/presentation/transaction_providers.dart';
import '../dashboard_providers.dart';

class CategoryChartCard extends ConsumerWidget {
  const CategoryChartCard({super.key});

  static const _maxSlices = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(dashboardExpenseByCategoryProvider);
    final categories = ref.watch(categoriesByIdProvider);
    final scheme = Theme.of(context).colorScheme;

    return SectionCard(
      title: 'Para onde foi o dinheiro',
      child: AsyncValueView(
        value: totals,
        data: (items) {
          if (items.isEmpty) {
            return const Text('Nenhuma saída registrada neste mês.');
          }
          final slices = _groupSmallSlices(items);
          final total = slices.fold(0, (sum, item) => sum + item.totalCents);
          Color colorOf(CategoryTotal item) {
            final category = categories[item.categoryId];
            return category == null ? scheme.outline : Color(category.color);
          }

          String nameOf(CategoryTotal item) =>
              categories[item.categoryId]?.name ??
              (item.categoryId == null ? 'Sem categoria' : 'Outras');

          return Column(
            children: [
              SizedBox(
                height: 180,
                child: Semantics(
                  label: 'Gráfico de saídas por categoria',
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 48,
                      sectionsSpace: 2,
                      sections: [
                        for (final item in slices)
                          PieChartSectionData(
                            value: item.totalCents.toDouble(),
                            color: colorOf(item),
                            radius: 36,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final item in slices)
                _LegendRow(
                  color: colorOf(item),
                  label: nameOf(item),
                  cents: item.totalCents,
                  percent: total == 0 ? 0 : (item.totalCents * 100 / total).round(),
                ),
            ],
          );
        },
      ),
    );
  }

  List<CategoryTotal> _groupSmallSlices(List<CategoryTotal> items) {
    if (items.length <= _maxSlices) return items;
    final head = items.take(_maxSlices - 1).toList();
    final rest = items
        .skip(_maxSlices - 1)
        .fold(0, (sum, item) => sum + item.totalCents);
    return [...head, CategoryTotal(categoryId: -1, totalCents: rest)];
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.cents,
    required this.percent,
  });

  final Color color;
  final String label;
  final int cents;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          Text('$percent%  ', style: textTheme.bodySmall),
          Text(Money.format(cents), style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class EvolutionChartCard extends ConsumerWidget {
  const EvolutionChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SectionCard(
      title: 'Últimos 6 meses',
      child: AsyncValueView(
        value: ref.watch(dashboardEvolutionProvider),
        data: (months) {
          final maxValue = months.fold(
            0,
            (max, m) => [max, m.incomeCents, m.expenseCents]
                .reduce((a, b) => a > b ? a : b),
          );
          return Column(
            children: [
              SizedBox(
                height: 200,
                child: Semantics(
                  label: 'Gráfico de entradas e saídas dos últimos 6 meses',
                  child: BarChart(
                    BarChartData(
                      maxY: maxValue == 0 ? 1.0 : maxValue * 1.15,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                              BarTooltipItem(
                            Money.format(rod.toY.round()),
                            TextStyle(color: scheme.onInverseSurface),
                          ),
                          getTooltipColor: (_) => scheme.inverseSurface,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= months.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  Dates.shortMonth(months[index].month),
                                  style: textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < months.length; i++)
                          BarChartGroupData(
                            x: i,
                            barsSpace: 4,
                            barRods: [
                              BarChartRodData(
                                toY: months[i].incomeCents.toDouble(),
                                color: scheme.income,
                                width: 10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              BarChartRodData(
                                toY: months[i].expenseCents.toDouble(),
                                color: scheme.expense,
                                width: 10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Dot(color: scheme.income, label: 'Entradas'),
                  const SizedBox(width: 16),
                  _Dot(color: scheme.expense, label: 'Saídas'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
