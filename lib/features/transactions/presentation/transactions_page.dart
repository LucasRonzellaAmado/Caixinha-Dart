import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/money_text.dart';
import '../domain/finance_calculator.dart';
import 'transaction_providers.dart';
import 'widgets/transaction_filter_bar.dart';
import 'widgets/transaction_list.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(filteredTransactionsProvider);
    final hasFilters = ref.watch(
      transactionFilterProvider.select((filter) => filter.hasExtraFilters),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lançamentos'),
        actions: [
          IconButton(
            tooltip: 'Categorias',
            onPressed: () => context.push(AppRoutes.categories),
            icon: const Icon(Icons.category_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'transactions-fab',
        onPressed: () => context.push(AppRoutes.newTransaction),
        icon: const Icon(Icons.add),
        label: const Text('Lançar'),
      ),
      body: Column(
        children: [
          const TransactionFilterBar(),
          Expanded(
            child: AsyncValueView(
              value: transactions,
              data: (items) => items.isEmpty
                  ? EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Nada por aqui',
                      message: hasFilters
                          ? 'Nenhum lançamento com esses filtros.'
                          : 'Registre sua primeira entrada ou saída do mês.',
                      action: hasFilters
                          ? OutlinedButton(
                              onPressed: () => ref
                                  .read(transactionFilterProvider.notifier)
                                  .clear(),
                              child: const Text('Limpar filtros'),
                            )
                          : null,
                    )
                  : Column(
                      children: [
                        _PeriodSummary(
                          summary: FinanceCalculator.summarize(items),
                        ),
                        Expanded(child: TransactionList(transactions: items)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSummary extends StatelessWidget {
  const _PeriodSummary({required this.summary});

  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _Item(
            label: 'Entradas',
            child: MoneyText(summary.incomeCents, colored: true, style: style),
          ),
          _Item(
            label: 'Saídas',
            child: MoneyText(
              -(summary.expenseCents + summary.proLaboreCents),
              colored: true,
              style: style,
            ),
          ),
          _Item(
            label: 'Resultado',
            child: MoneyText(summary.balanceCents, colored: true, style: style),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        child,
      ],
    );
  }
}
