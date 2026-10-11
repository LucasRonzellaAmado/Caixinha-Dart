import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../transactions/domain/finance_calculator.dart';
import '../../../transactions/domain/transaction_enums.dart';
import '../dashboard_providers.dart';

class SummaryCard extends ConsumerWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scope = ref.watch(dashboardScopeProvider);
    final balance = ref.watch(dashboardBalanceProvider);
    final summary = ref.watch(dashboardSummaryProvider);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scope == TransactionScope.business
                  ? 'Saldo do negócio'
                  : 'Saldo pessoal',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            MoneyText(
              balance.value ?? 0,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              Dates.monthYear(DateTime.now()),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            AsyncValueView(
              value: summary,
              data: (data) => _MonthFigures(summary: data, scope: scope),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthFigures extends StatelessWidget {
  const _MonthFigures({required this.summary, required this.scope});

  final FinanceSummary summary;
  final TransactionScope scope;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBusiness = scope == TransactionScope.business;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Figure(
          label: 'Entradas',
          cents: summary.incomeCents,
          icon: Icons.arrow_downward,
          color: scheme.income,
        ),
        _Figure(
          label: 'Saídas',
          cents: summary.expenseCents,
          icon: Icons.arrow_upward,
          color: scheme.expense,
        ),
        _Figure(
          label: isBusiness ? 'Lucro' : 'Sobrou',
          cents: summary.profitCents,
          icon: Icons.trending_up,
          color: summary.profitCents >= 0 ? scheme.income : scheme.expense,
        ),
        if (isBusiness)
          _Figure(
            label: 'Pró-labore',
            cents: summary.proLaboreCents,
            icon: Icons.account_balance_wallet_outlined,
            color: scheme.proLabore,
          ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.cents,
    required this.icon,
    required this.color,
  });

  final String label;
  final int cents;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 130),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodySmall),
                  MoneyText(cents, style: theme.textTheme.titleSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
