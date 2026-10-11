import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../customers/presentation/customer_providers.dart';
import '../../../mei_limit/presentation/mei_providers.dart';
import '../../../mei_limit/presentation/widgets/mei_thermometer.dart';
import '../../../reminders/domain/fiscal_deadline.dart';
import '../../../reminders/presentation/reminder_providers.dart';
import '../../../transactions/domain/transaction_enums.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../dashboard_providers.dart';

class ScopeToggle extends ConsumerWidget {
  const ScopeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<TransactionScope>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: TransactionScope.business,
          icon: Icon(Icons.storefront_outlined),
          label: Text('Negócio'),
        ),
        ButtonSegment(
          value: TransactionScope.personal,
          icon: Icon(Icons.person_outline),
          label: Text('Pessoal'),
        ),
      ],
      selected: {ref.watch(dashboardScopeProvider)},
      onSelectionChanged: (selection) =>
          ref.read(dashboardScopeProvider.notifier).select(selection.first),
    );
  }
}

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => context.push(
              AppRoutes.newTransactionOf(type: TransactionType.income.name),
            ),
            icon: Icon(Icons.arrow_downward, color: scheme.income),
            label: const Text('Entrada'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => context.push(
              AppRoutes.newTransactionOf(type: TransactionType.expense.name),
            ),
            icon: Icon(Icons.arrow_upward, color: scheme.expense),
            label: const Text('Saída'),
          ),
        ),
      ],
    );
  }
}

class MeiLimitCard extends ConsumerWidget {
  const MeiLimitCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      title: 'Limite do MEI',
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(AppRoutes.meiLimit),
      child: AsyncValueView(
        value: ref.watch(meiStatusProvider),
        data: (status) => MeiThermometer(status: status),
      ),
    );
  }
}

class NextDeadlineCard extends ConsumerWidget {
  const NextDeadlineCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deadlines = ref.watch(upcomingDeadlinesProvider);
    final paid = ref.watch(paidCompetencesProvider).value ?? const <String>{};
    final next = deadlines
        .where(
          (d) => d.kind == DeadlineKind.dasn || !paid.contains(d.competenceKey),
        )
        .firstOrNull;
    if (next == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final days = Dates.daysBetween(now, next.dueDate);
    final scheme = Theme.of(context).colorScheme;
    final urgent = days <= 5;

    return Card(
      color: urgent ? scheme.errorContainer : scheme.secondaryContainer,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => context.push(AppRoutes.reminders),
        leading: Icon(
          Icons.event_outlined,
          color: urgent ? scheme.onErrorContainer : scheme.onSecondaryContainer,
        ),
        title: Text(next.title),
        subtitle: Text(
          'Vence ${Dates.relativeDays(now, next.dueDate)} (${Dates.day(next.dueDate)})',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class ReceivablesCard extends ConsumerWidget {
  const ReceivablesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(totalReceivableProvider).value ?? 0;
    if (total == 0) return const SizedBox.shrink();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => context.push(AppRoutes.customers),
        leading: const Icon(Icons.request_quote_outlined),
        title: const Text('A receber de clientes'),
        subtitle: MoneyText(total),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class RecentTransactionsCard extends ConsumerWidget {
  const RecentTransactionsCard({super.key});

  static const _limit = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      title: 'Últimos lançamentos',
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: AsyncValueView(
        value: ref.watch(dashboardMonthTransactionsProvider),
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Nenhum lançamento neste mês ainda.'),
            );
          }
          return Column(
            children: [
              for (final transaction in transactions.take(_limit))
                TransactionTile(transaction: transaction),
              TextButton(
                onPressed: () => context.go(AppRoutes.transactions),
                child: const Text('Ver todos'),
              ),
            ],
          );
        },
      ),
    );
  }
}
