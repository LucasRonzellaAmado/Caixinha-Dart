import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/dates.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/money_text.dart';
import '../../domain/financial_transaction.dart';
import '../transaction_providers.dart';
import 'transaction_tile.dart';

sealed class _ListItem {
  const _ListItem();
}

final class _DayHeader extends _ListItem {
  const _DayHeader(this.day, this.totalCents);

  final DateTime day;
  final int totalCents;
}

final class _TransactionItem extends _ListItem {
  const _TransactionItem(this.transaction);

  final FinancialTransaction transaction;
}

class TransactionList extends ConsumerWidget {
  const TransactionList({super.key, required this.transactions});

  final List<FinancialTransaction> transactions;

  List<_ListItem> _buildItems() {
    final items = <_ListItem>[];
    DateTime? currentDay;
    var headerIndex = 0;
    var dayTotal = 0;
    for (final transaction in transactions) {
      final day = Dates.dateOnly(transaction.date);
      if (currentDay == null || !Dates.isSameDay(currentDay, day)) {
        if (currentDay != null) {
          items[headerIndex] = _DayHeader(currentDay, dayTotal);
        }
        currentDay = day;
        dayTotal = 0;
        headerIndex = items.length;
        items.add(_DayHeader(day, 0));
      }
      dayTotal += transaction.signedAmountCents;
      items.add(_TransactionItem(transaction));
    }
    if (currentDay != null) items[headerIndex] = _DayHeader(currentDay, dayTotal);
    return items;
  }

  Future<bool> _delete(
    BuildContext context,
    WidgetRef ref,
    FinancialTransaction transaction,
  ) async {
    final id = transaction.id;
    if (id == null) return false;
    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.delete(id);
    if (!context.mounted) return result.isOk;
    final failure = result.failureOrNull;
    if (failure != null) {
      showFailure(context, failure);
      return false;
    }
    showMessage(
      context,
      'Lançamento apagado.',
      action: SnackBarAction(
        label: 'Desfazer',
        onPressed: () => repository.save(transaction.copyWith(id: null)),
      ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _buildItems();
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: items.length,
      itemBuilder: (context, index) => switch (items[index]) {
        _DayHeader(:final day, :final totalCents) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      Dates.weekdayLong(day),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                MoneyText(
                  totalCents,
                  showSign: true,
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
        _TransactionItem(:final transaction) => Dismissible(
            key: ValueKey('transaction-${transaction.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              color: theme.colorScheme.errorContainer,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.onErrorContainer,
                semanticLabel: 'Apagar',
              ),
            ),
            confirmDismiss: (_) => _delete(context, ref, transaction),
            child: TransactionTile(transaction: transaction),
          ),
      },
    );
  }
}
