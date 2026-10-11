import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../../../core/widgets/category_icons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/feedback.dart';
import '../domain/transaction_category.dart';
import '../domain/transaction_enums.dart';
import 'transaction_providers.dart';
import 'widgets/category_dialog.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    TransactionCategory? category,
  }) async {
    final result = await showDialog<TransactionCategory>(
      context: context,
      builder: (_) => CategoryDialog(initial: category),
    );
    if (result == null) return;
    final saved = await ref.read(categoryRepositoryProvider).save(result);
    if (!context.mounted) return;
    if (saved case Err(:final failure)) showFailure(context, failure);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TransactionCategory category,
  ) async {
    final id = category.id;
    if (id == null) return;
    final confirmed = await confirm(
      context,
      title: 'Apagar "${category.name}"?',
      message: 'Os lançamentos dessa categoria continuam salvos, '
          'só ficam sem categoria.',
      confirmLabel: 'Apagar',
      destructive: true,
    );
    if (!confirmed) return;
    final result = await ref.read(categoryRepositoryProvider).delete(id);
    if (!context.mounted) return;
    if (result case Err(:final failure)) showFailure(context, failure);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nova categoria'),
      ),
      body: AsyncValueView(
        value: ref.watch(categoriesProvider),
        data: (categories) => ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            for (final type in [TransactionType.income, TransactionType.expense]) ...[
              SectionHeader(
                type == TransactionType.income ? 'Entradas' : 'Saídas',
              ),
              for (final category in categories.where((c) => c.type == type))
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(category.color).withValues(alpha: 0.15),
                    foregroundColor: Color(category.color),
                    child: Icon(iconForKey(category.iconKey)),
                  ),
                  title: Text(category.name),
                  subtitle: category.archived ? const Text('Arquivada') : null,
                  onTap: () => _edit(context, ref, category: category),
                  trailing: IconButton(
                    tooltip: 'Apagar ${category.name}',
                    onPressed: () => _delete(context, ref, category),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
