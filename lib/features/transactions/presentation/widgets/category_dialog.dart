import 'package:flutter/material.dart';

import '../../../../core/widgets/category_icons.dart';
import '../../domain/transaction_category.dart';
import '../../domain/transaction_enums.dart';

class CategoryDialog extends StatefulWidget {
  const CategoryDialog({super.key, this.initial});

  final TransactionCategory? initial;

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late TransactionType _type = widget.initial?.type ?? TransactionType.expense;
  late int _color = widget.initial?.color ?? categoryColors.first;
  late String _iconKey = widget.initial?.iconKey ?? 'other';
  late bool _archived = widget.initial?.archived ?? false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final initial = widget.initial;
    final category = initial == null
        ? TransactionCategory(
            name: name,
            type: _type,
            color: _color,
            iconKey: _iconKey,
          )
        : initial.copyWith(
            name: name,
            color: _color,
            iconKey: _iconKey,
            archived: _archived,
          );
    Navigator.of(context).pop(category);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initial == null;
    return AlertDialog(
      title: Text(isNew ? 'Nova categoria' : 'Editar categoria'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: isNew,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            if (isNew)
              SegmentedButton<TransactionType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Entrada'),
                  ),
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Saída'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) =>
                    setState(() => _type = selection.first),
              ),
            const SizedBox(height: 16),
            Text('Cor', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in categoryColors)
                  Semantics(
                    button: true,
                    selected: color == _color,
                    label: 'Cor',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _color = color),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(color),
                        child: color == _color
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Ícone', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final entry in categoryIcons.entries)
                  IconButton.filledTonal(
                    isSelected: entry.key == _iconKey,
                    tooltip: entry.key,
                    onPressed: () => setState(() => _iconKey = entry.key),
                    icon: Icon(entry.value),
                    selectedIcon: Icon(entry.value, color: Color(_color)),
                  ),
              ],
            ),
            if (!isNew)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Arquivar'),
                subtitle: const Text('Some dos atalhos, mas o histórico fica.'),
                value: _archived,
                onChanged: (value) => setState(() => _archived = value),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}
