import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/common.dart';
import '../../domain/transaction_enums.dart';
import '../transaction_providers.dart';

enum _ScopeOption { all, business, personal }

class TransactionFilterBar extends ConsumerStatefulWidget {
  const TransactionFilterBar({super.key});

  @override
  ConsumerState<TransactionFilterBar> createState() =>
      _TransactionFilterBarState();
}

class _TransactionFilterBarState extends ConsumerState<TransactionFilterBar> {
  late final TextEditingController _search = TextEditingController(
    text: ref.read(transactionFilterProvider).query,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(transactionFilterProvider);
    final notifier = ref.read(transactionFilterProvider.notifier);
    final scopeOption = switch (filter.scope) {
      null => _ScopeOption.all,
      TransactionScope.business => _ScopeOption.business,
      TransactionScope.personal => _ScopeOption.personal,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonthSelector(
            month: notifier.month,
            onPrevious: notifier.previousMonth,
            onNext: notifier.nextMonth,
          ),
          SegmentedButton<_ScopeOption>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _ScopeOption.all, label: Text('Tudo')),
              ButtonSegment(value: _ScopeOption.business, label: Text('Negócio')),
              ButtonSegment(value: _ScopeOption.personal, label: Text('Pessoal')),
            ],
            selected: {scopeOption},
            onSelectionChanged: (selection) => notifier.setScope(
              switch (selection.first) {
                _ScopeOption.all => null,
                _ScopeOption.business => TransactionScope.business,
                _ScopeOption.personal => TransactionScope.personal,
              },
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TypeChip(
                  label: 'Todos',
                  selected: filter.type == null,
                  onSelected: () => notifier.setType(null),
                ),
                for (final type in TransactionType.values)
                  _TypeChip(
                    label: type.label,
                    selected: filter.type == type,
                    onSelected: () => notifier.setType(type),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por descrição',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              suffixIcon: filter.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        notifier.setQuery('');
                      },
                    ),
            ),
            onChanged: notifier.setQuery,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
