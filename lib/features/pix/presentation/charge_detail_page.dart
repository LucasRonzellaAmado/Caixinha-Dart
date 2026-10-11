import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/feedback.dart';
import '../../customers/presentation/customer_providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../transactions/domain/transaction_enums.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../domain/charge.dart';
import 'charge_providers.dart';

class ChargeDetailPage extends ConsumerWidget {
  const ChargeDetailPage({super.key, required this.chargeId});

  final int chargeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cobrança Pix')),
      body: AsyncValueView(
        value: ref.watch(chargeByIdProvider(chargeId)),
        data: (charge) => charge == null
            ? const EmptyState(
                icon: Icons.search_off,
                title: 'Cobrança não encontrada',
                message: 'Ela pode ter sido apagada.',
              )
            : _ChargeDetail(charge: charge),
      ),
    );
  }
}

class _ChargeDetail extends ConsumerWidget {
  const _ChargeDetail({required this.charge});

  final Charge charge;

  Future<void> _receive(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirm(
      context,
      title: 'Marcar como recebida?',
      message: 'Vou lançar ${Money.format(charge.amountCents)} como entrada '
          'do negócio, paga via Pix.',
      confirmLabel: 'Recebi',
    );
    if (!confirmed) return;
    final categories = await ref.read(categoryRepositoryProvider).fetchAll();
    final categoryId = categories
        .where((c) => c.type == TransactionType.income && !c.archived)
        .firstOrNull
        ?.id;
    final result = await ref
        .read(chargeServiceProvider)
        .receive(charge, categoryId: categoryId);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        showMessage(context, 'Recebimento lançado!');
      case Err(:final failure):
        showFailure(context, failure);
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirm(
      context,
      title: 'Cancelar cobrança?',
      message: 'O QR Code continua funcionando se o cliente já tiver copiado, '
          'mas a cobrança sai da lista de contas a receber.',
      confirmLabel: 'Cancelar cobrança',
      destructive: true,
    );
    if (!confirmed) return;
    final result = await ref.read(chargeServiceProvider).cancel(charge);
    if (!context.mounted) return;
    if (result case Err(:final failure)) showFailure(context, failure);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final customer = ref.watch(customersByIdProvider)[charge.customerId];
    final theme = Theme.of(context);
    final payload = settings == null
        ? const Err<String>(ValidationFailure('Carregando configurações...'))
        : buildChargePayload(settings, charge);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          Money.format(charge.amountCents),
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (charge.description.isNotEmpty)
          Text(
            charge.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        if (customer != null)
          Text(
            customer.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        const SizedBox(height: 8),
        Center(
          child: Chip(
            label: Text(charge.status.label),
            avatar: Icon(
              charge.isPending ? Icons.schedule : Icons.check_circle_outline,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (charge.isPending)
          switch (payload) {
            Ok(:final value) => _QrSection(charge: charge, payload: value),
            Err(:final failure) => _PayloadError(message: failure.message),
          },
        if (charge.status == ChargeStatus.received)
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(
              'Recebida em ${Dates.day(charge.receivedAt ?? charge.createdAt)}',
            ),
            subtitle: const Text('Já lançada como entrada do negócio.'),
          ),
        ListTile(
          leading: const Icon(Icons.event_outlined),
          title: Text('Criada em ${Dates.day(charge.createdAt)}'),
          subtitle: charge.dueDate == null
              ? null
              : Text('Vencimento: ${Dates.day(charge.dueDate!)}'),
        ),
        ListTile(
          leading: const Icon(Icons.tag),
          title: const Text('Identificador'),
          subtitle: Text(charge.txid),
        ),
        if (charge.isPending) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _receive(context, ref),
            icon: const Icon(Icons.price_check),
            label: const Text('Marcar como recebida'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _cancel(context, ref),
            child: const Text('Cancelar cobrança'),
          ),
        ],
      ],
    );
  }
}

class _QrSection extends StatelessWidget {
  const _QrSection({required this.charge, required this.payload});

  final Charge charge;
  final String payload;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          image: true,
          label: 'QR Code Pix de ${Money.format(charge.amountCents)}',
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: payload,
              size: 240,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Pix copia e cola', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        SelectableText(
          payload,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: payload));
                  if (context.mounted) showMessage(context, 'Código copiado!');
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text: 'Pix de ${Money.format(charge.amountCents)}'
                        '${charge.description.isEmpty ? '' : ' (${charge.description})'}'
                        '\n\nCopia e cola:\n$payload',
                  ),
                ),
                icon: const Icon(Icons.share),
                label: const Text('Enviar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PayloadError extends StatelessWidget {
  const _PayloadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(message),
        trailing: TextButton(
          onPressed: () => context.push(AppRoutes.settings),
          child: const Text('Ajustar'),
        ),
      ),
    );
  }
}
