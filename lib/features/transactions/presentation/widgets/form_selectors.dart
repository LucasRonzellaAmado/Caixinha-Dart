import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/category_icons.dart';
import '../../../customers/presentation/customer_providers.dart';
import '../../domain/transaction_enums.dart';
import '../transaction_providers.dart';

class TransactionTypeSelector extends StatelessWidget {
  const TransactionTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TransactionType>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: TransactionType.income,
          icon: Icon(Icons.arrow_downward),
          label: Text('Entrada'),
        ),
        ButtonSegment(
          value: TransactionType.expense,
          icon: Icon(Icons.arrow_upward),
          label: Text('Saída'),
        ),
        ButtonSegment(
          value: TransactionType.proLabore,
          icon: Icon(Icons.account_balance_wallet_outlined),
          label: Text('Pró-labore'),
        ),
      ],
      selected: {value},
      onSelectionChanged:
          enabled ? (selection) => onChanged(selection.first) : null,
    );
  }
}

class ScopeSelector extends StatelessWidget {
  const ScopeSelector({super.key, required this.value, required this.onChanged});

  final TransactionScope value;
  final ValueChanged<TransactionScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TransactionScope>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: TransactionScope.business,
          icon: Icon(Icons.storefront_outlined),
          label: Text('Do negócio'),
        ),
        ButtonSegment(
          value: TransactionScope.personal,
          icon: Icon(Icons.person_outline),
          label: Text('Pessoal'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class CategorySelector extends ConsumerWidget {
  const CategorySelector({
    super.key,
    required this.type,
    required this.value,
    required this.onChanged,
  });

  final TransactionType type;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = (ref.watch(categoriesProvider).value ?? const [])
        .where((c) => c.type == type && (!c.archived || c.id == value))
        .toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in categories)
          ChoiceChip(
            avatar: Icon(
              iconForKey(category.iconKey),
              color: Color(category.color),
            ),
            label: Text(category.name),
            selected: category.id == value,
            onSelected: (selected) => onChanged(selected ? category.id : null),
          ),
        ActionChip(
          avatar: const Icon(Icons.tune),
          label: const Text('Categorias'),
          onPressed: () => context.push(AppRoutes.categories),
        ),
      ],
    );
  }
}

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final method in PaymentMethod.values)
          ChoiceChip(
            label: Text(method.label),
            selected: method == value,
            onSelected: (_) => onChanged(method),
          ),
      ],
    );
  }
}

class CustomerSelector extends ConsumerWidget {
  const CustomerSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider).value ?? const [];
    return DropdownMenu<int?>(
      key: ValueKey('customer-$value-${customers.length}'),
      initialSelection: value,
      expandedInsets: EdgeInsets.zero,
      label: const Text('Cliente (opcional)'),
      leadingIcon: const Icon(Icons.person_outline),
      onSelected: onChanged,
      dropdownMenuEntries: [
        const DropdownMenuEntry<int?>(value: null, label: 'Nenhum'),
        for (final customer in customers)
          DropdownMenuEntry<int?>(value: customer.id, label: customer.name),
      ],
    );
  }
}
