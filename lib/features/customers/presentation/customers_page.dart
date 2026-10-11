import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/money_text.dart';
import '../domain/receivables.dart';
import 'customer_providers.dart';

class CustomersPage extends ConsumerWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes e contas a receber')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newCustomer),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Novo cliente'),
      ),
      body: AsyncValueView(
        value: ref.watch(customerBalancesProvider),
        data: (balances) {
          if (balances.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'Nenhum cliente ainda',
              message: 'Cadastre seus clientes para saber quem te deve '
                  'e cobrar com Pix em poucos toques.',
            );
          }
          final total = balances.fold(0, (sum, b) => sum + b.openCents);
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SectionCard(
                  title: 'Total a receber',
                  child: MoneyText(
                    total,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              for (final balance in balances) _CustomerTile(balance: balance),
            ],
          );
        },
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.balance});

  final CustomerBalance balance;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final receivable = balance.receivable;
    final name = balance.customer.name;
    return ListTile(
      onTap: () {
        final id = balance.customer.id;
        if (id != null) context.push(AppRoutes.customer(id));
      },
      leading: CircleAvatar(
        child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
      ),
      title: Text(name),
      subtitle: receivable == null
          ? const Text('Nada em aberto')
          : Text(
              'Deve ${Money.format(receivable.totalCents)} '
              'há ${receivable.daysOpen(DateTime.now())} dias',
              style: TextStyle(
                color: receivable.daysOpen(DateTime.now()) > 30
                    ? scheme.expense
                    : null,
              ),
            ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
