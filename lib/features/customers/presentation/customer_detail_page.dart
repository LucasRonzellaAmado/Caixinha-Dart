import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/money_text.dart';
import '../../pix/presentation/charge_providers.dart';
import '../../pix/presentation/widgets/charge_tile.dart';
import '../../transactions/domain/finance_calculator.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../../transactions/presentation/widgets/transaction_tile.dart';
import '../domain/customer.dart';
import '../domain/receivables.dart';
import 'customer_providers.dart';

class CustomerDetailPage extends ConsumerWidget {
  const CustomerDetailPage({super.key, required this.customerId});

  final int customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(customerByIdProvider(customerId));
    return switch (value) {
      AsyncData(value: null) => const NotFoundPage(),
      AsyncData(value: final Customer customer) =>
        _CustomerDetail(customer: customer, customerId: customerId),
      _ => Scaffold(
          appBar: AppBar(),
          body: AsyncValueView(
            value: value,
            data: (_) => const SizedBox.shrink(),
          ),
        ),
    };
  }
}

class _CustomerDetail extends ConsumerWidget {
  const _CustomerDetail({required this.customer, required this.customerId});

  final Customer customer;
  final int customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charges = ref.watch(customerChargesProvider(customerId));
    final transactions = ref.watch(customerTransactionsProvider(customerId));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            tooltip: 'Editar',
            onPressed: () => context.push(AppRoutes.editCustomer(customerId)),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (customer.phone != null)
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(customer.phone!),
            ),
          if (customer.document != null)
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(customer.document!),
            ),
          if (customer.notes != null)
            ListTile(
              leading: const Icon(Icons.notes),
              title: Text(customer.notes!),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.newChargeFor(customerId)),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Cobrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      AppRoutes.newTransactionOf(customerId: customerId),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Lançar'),
                  ),
                ),
              ],
            ),
          ),
          AsyncValueView(
            value: charges,
            data: (items) {
              final pending = items.where((c) => c.isPending).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader('Em aberto'),
                  if (pending.isEmpty)
                    const ListTile(title: Text('Nada em aberto. 🎉'))
                  else ...[
                    ListTile(
                      title: const Text('Total devido'),
                      trailing: MoneyText(
                        Receivables.total(pending),
                        style: textTheme.titleMedium,
                      ),
                    ),
                    for (final charge in pending) ChargeTile(charge: charge),
                  ],
                ],
              );
            },
          ),
          const SectionHeader('Histórico'),
          AsyncValueView(
            value: transactions,
            data: (items) => items.isEmpty
                ? const ListTile(title: Text('Nenhum lançamento com esse cliente.'))
                : Column(
                    children: [
                      ListTile(
                        title: const Text('Total já recebido'),
                        trailing: MoneyText(
                          FinanceCalculator.summarize(items).incomeCents,
                          style: textTheme.titleSmall,
                        ),
                      ),
                      for (final transaction in items)
                        TransactionTile(transaction: transaction),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
