import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../customers/presentation/customer_providers.dart';
import '../../domain/charge.dart';

class ChargeTile extends ConsumerWidget {
  const ChargeTile({super.key, required this.charge});

  final Charge charge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final customer = ref.watch(customersByIdProvider)[charge.customerId];
    final now = DateTime.now();
    final overdue = charge.isOverdue(now);
    final (icon, color) = switch (charge.status) {
      ChargeStatus.pending when overdue => (Icons.warning_amber, scheme.expense),
      ChargeStatus.pending => (Icons.schedule, scheme.warning),
      ChargeStatus.received => (Icons.check_circle_outline, scheme.income),
      ChargeStatus.canceled => (Icons.block, scheme.outline),
    };
    final title = charge.description.isNotEmpty
        ? charge.description
        : customer?.name ?? 'Cobrança Pix';
    final due = charge.dueDate;
    final subtitle = [
      if (customer != null && charge.description.isNotEmpty) customer.name,
      switch (charge.status) {
        ChargeStatus.pending when due != null =>
          overdue ? 'Venceu ${Dates.relativeDays(now, due)}' : 'Vence ${Dates.relativeDays(now, due)}',
        ChargeStatus.pending => 'Criada ${Dates.relativeDays(now, charge.createdAt)}',
        ChargeStatus.received => 'Recebida em ${Dates.day(charge.receivedAt ?? charge.createdAt)}',
        ChargeStatus.canceled => 'Cancelada',
      },
    ].join(' • ');

    return ListTile(
      onTap: () {
        final id = charge.id;
        if (id != null) context.push(AppRoutes.charge(id));
      },
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        child: Icon(icon),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: MoneyText(
        charge.amountCents,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
