import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../transactions/domain/transaction_enums.dart';
import 'dashboard_providers.dart';
import 'widgets/charts.dart';
import 'widgets/dashboard_cards.dart';
import 'widgets/summary_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    final period = hour < 12
        ? 'Bom dia'
        : hour < 18
            ? 'Boa tarde'
            : 'Boa noite';
    final firstName = name.trim().split(' ').first;
    return firstName.isEmpty ? period : '$period, $firstName';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final isBusiness =
        ref.watch(dashboardScopeProvider) == TransactionScope.business;
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(
        title: Text(_greeting(settings?.ownerName ?? '')),
        actions: [
          IconButton(
            tooltip: 'Configurações',
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboard-fab',
        onPressed: () => context.push(AppRoutes.newTransaction),
        icon: const Icon(Icons.add),
        label: const Text('Lançar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const ScopeToggle(),
          gap,
          const SummaryCard(),
          gap,
          const QuickActions(),
          gap,
          if (isBusiness) ...[
            const NextDeadlineCard(),
            const ReceivablesCard(),
            gap,
            const MeiLimitCard(),
            gap,
          ],
          const CategoryChartCard(),
          gap,
          const EvolutionChartCard(),
          gap,
          const RecentTransactionsCard(),
        ],
      ),
    );
  }
}
