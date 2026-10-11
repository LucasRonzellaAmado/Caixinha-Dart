import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/category_icons.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../customers/presentation/customer_providers.dart';
import '../../domain/financial_transaction.dart';
import '../../domain/transaction_enums.dart';
import '../transaction_providers.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({super.key, required this.transaction});

  final FinancialTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final category = ref.watch(categoriesByIdProvider)[transaction.categoryId];
    final customer = ref.watch(customersByIdProvider)[transaction.customerId];
    final isProLabore = transaction.type == TransactionType.proLabore;
    final color = isProLabore
        ? scheme.proLabore
        : category != null
            ? Color(category.color)
            : scheme.outline;
    final icon = isProLabore
        ? Icons.account_balance_wallet_outlined
        : iconForKey(category?.iconKey ?? 'other');
    final title = transaction.description.isNotEmpty
        ? transaction.description
        : category?.name ?? transaction.type.label;
    final details = [
      if (category != null && transaction.description.isNotEmpty) category.name,
      if (isProLabore) 'Retirada do dono',
      transaction.paymentMethod.label,
      if (customer != null) customer.name,
      if (transaction.scope == TransactionScope.personal) 'Pessoal',
    ];

    return ListTile(
      onTap: () {
        final id = transaction.id;
        if (id != null) context.push(AppRoutes.editTransaction(id));
      },
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        child: Icon(icon),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        details.join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: MoneyText(
        transaction.signedAmountCents,
        colored: true,
        showSign: true,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
