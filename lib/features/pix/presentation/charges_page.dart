import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/money_text.dart';
import '../../customers/domain/receivables.dart';
import '../../settings/presentation/settings_providers.dart';
import '../domain/charge.dart';
import 'charge_providers.dart';
import 'widgets/charge_tile.dart';

class ChargesPage extends ConsumerWidget {
  const ChargesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPixKey = ref.watch(settingsProvider).value?.hasPixKey ?? true;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cobranças Pix'),
          actions: [
            IconButton(
              tooltip: 'Clientes',
              onPressed: () => context.push(AppRoutes.customers),
              icon: const Icon(Icons.people_outline),
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'A receber'), Tab(text: 'Finalizadas')],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'charges-fab',
          onPressed: () => context.push(AppRoutes.newCharge),
          icon: const Icon(Icons.qr_code_2),
          label: const Text('Nova cobrança'),
        ),
        body: Column(
          children: [
            if (!hasPixKey) const _PixKeyBanner(),
            Expanded(
              child: TabBarView(
                children: [
                  _ChargeList(
                    value: ref.watch(pendingChargesProvider),
                    showTotal: true,
                    emptyMessage:
                        'Gere um QR Code Pix e mande para o cliente pagar.',
                  ),
                  _ChargeList(
                    value: ref.watch(closedChargesProvider),
                    emptyMessage: 'As cobranças pagas ou canceladas aparecem aqui.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChargeList extends StatelessWidget {
  const _ChargeList({
    required this.value,
    required this.emptyMessage,
    this.showTotal = false,
  });

  final AsyncValue<List<Charge>> value;
  final String emptyMessage;
  final bool showTotal;

  @override
  Widget build(BuildContext context) {
    return AsyncValueView(
      value: value,
      data: (charges) {
        if (charges.isEmpty) {
          return EmptyState(
            icon: Icons.qr_code_2,
            title: 'Nenhuma cobrança',
            message: emptyMessage,
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            if (showTotal)
              ListTile(
                title: const Text('Total a receber'),
                trailing: MoneyText(
                  Receivables.total(charges),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            for (final charge in charges) ChargeTile(charge: charge),
          ],
        );
      },
    );
  }
}

class _PixKeyBanner extends StatelessWidget {
  const _PixKeyBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MaterialBanner(
      backgroundColor: scheme.tertiaryContainer,
      content: Text(
        'Cadastre sua chave Pix para gerar QR Codes.',
        style: TextStyle(color: scheme.onTertiaryContainer),
      ),
      leading: Icon(Icons.key, color: scheme.onTertiaryContainer),
      actions: [
        TextButton(
          onPressed: () => context.push(AppRoutes.settings),
          child: const Text('Cadastrar'),
        ),
      ],
    );
  }
}
