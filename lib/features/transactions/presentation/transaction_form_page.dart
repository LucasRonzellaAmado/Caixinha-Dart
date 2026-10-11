import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/result/result.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/feedback.dart';
import '../domain/financial_transaction.dart';
import '../domain/transaction_enums.dart';
import 'transaction_providers.dart';
import 'widgets/form_selectors.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({
    super.key,
    this.transactionId,
    this.initialType = TransactionType.income,
    this.initialCustomerId,
  });

  final int? transactionId;
  final TransactionType initialType;
  final int? initialCustomerId;

  bool get isEditing => transactionId != null;

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();

  late TransactionType _type = widget.initialType;
  TransactionScope _scope = TransactionScope.business;
  DateTime _date = DateTime.now();
  int? _categoryId;
  PaymentMethod _paymentMethod = PaymentMethod.pix;
  late int? _customerId = widget.initialCustomerId;
  int? _chargeId;
  bool _mirrorAsPersonal = true;
  late bool _loading = widget.transactionId != null;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final id = widget.transactionId;
    if (id != null) _load(id);
  }

  Future<void> _load(int id) async {
    final transaction =
        await ref.read(transactionRepositoryProvider).findById(id);
    if (!mounted) return;
    if (transaction == null) {
      showMessage(context, 'Esse lançamento não existe mais.');
      context.pop();
      return;
    }
    setState(() {
      _type = transaction.type;
      _scope = transaction.scope;
      _date = transaction.date;
      _categoryId = transaction.categoryId;
      _paymentMethod = transaction.paymentMethod;
      _customerId = transaction.customerId;
      _chargeId = transaction.chargeId;
      _amount.text = AmountField.textFor(transaction.amountCents);
      _description.text = transaction.description;
      _notes.text = transaction.notes ?? '';
      _loading = false;
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _changeType(TransactionType type) {
    setState(() {
      _type = type;
      _categoryId = null;
      if (type == TransactionType.proLabore) {
        _scope = TransactionScope.business;
      }
    });
  }

  FinancialTransaction _buildTransaction(int cents) {
    final notes = _notes.text.trim();
    final isProLabore = _type == TransactionType.proLabore;
    return FinancialTransaction(
      id: widget.transactionId,
      type: _type,
      scope: isProLabore ? TransactionScope.business : _scope,
      amountCents: cents,
      date: _date,
      categoryId: isProLabore ? null : _categoryId,
      paymentMethod: _paymentMethod,
      customerId: _customerId,
      description: _description.text.trim(),
      notes: notes.isEmpty ? null : notes,
      chargeId: _chargeId,
    );
  }

  Future<void> _save() async {
    final cents = AmountField.centsOf(_amount);
    if (cents <= 0) {
      showMessage(context, 'Informe o valor.');
      return;
    }
    setState(() => _saving = true);
    final transaction = _buildTransaction(cents);
    final repository = ref.read(transactionRepositoryProvider);
    final shouldMirror = transaction.type == TransactionType.proLabore &&
        _mirrorAsPersonal &&
        !widget.isEditing;
    final Failure? failure = shouldMirror
        ? (await repository.saveAll([
            transaction,
            transaction.copyWith(
              type: TransactionType.income,
              scope: TransactionScope.personal,
              description: 'Pró-labore recebido',
              customerId: null,
            ),
          ]))
            .failureOrNull
        : (await repository.save(transaction)).failureOrNull;
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure != null) {
      showFailure(context, failure);
      return;
    }
    showMessage(context, widget.isEditing ? 'Lançamento atualizado.' : 'Lançamento salvo!');
    context.pop();
  }

  Future<void> _delete() async {
    final id = widget.transactionId;
    if (id == null) return;
    final confirmed = await confirm(
      context,
      title: 'Apagar lançamento?',
      message: 'Essa ação não pode ser desfeita.',
      confirmLabel: 'Apagar',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final result = await ref.read(transactionRepositoryProvider).delete(id);
    if (!mounted) return;
    switch (result) {
      case Ok():
        showMessage(context, 'Lançamento apagado.');
        context.pop();
      case Err(:final failure):
        showFailure(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProLabore = _type == TransactionType.proLabore;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar lançamento' : 'Novo lançamento'),
        actions: [
          if (widget.isEditing)
            IconButton(
              tooltip: 'Apagar',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                TransactionTypeSelector(value: _type, onChanged: _changeType),
                const SizedBox(height: 16),
                AmountField(
                  controller: _amount,
                  autofocus: !widget.isEditing,
                  large: true,
                ),
                const SizedBox(height: 16),
                if (isProLabore)
                  const _ProLaboreHint()
                else ...[
                  ScopeSelector(
                    value: _scope,
                    onChanged: (scope) => setState(() => _scope = scope),
                  ),
                  const SectionHeader('Categoria'),
                  CategorySelector(
                    type: _type,
                    value: _categoryId,
                    onChanged: (id) => setState(() => _categoryId = id),
                  ),
                ],
                const SectionHeader('Como foi pago'),
                PaymentMethodSelector(
                  value: _paymentMethod,
                  onChanged: (method) => setState(() => _paymentMethod = method),
                ),
                const SizedBox(height: 24),
                DateField(
                  label: 'Data',
                  value: _date,
                  onChanged: (date) {
                    if (date != null) setState(() => _date = date);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Ex.: Bolo de aniversário da Ana',
                  ),
                ),
                const SizedBox(height: 16),
                if (!isProLabore) ...[
                  CustomerSelector(
                    value: _customerId,
                    onChanged: (id) => setState(() => _customerId = id),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Observação'),
                ),
                if (isProLabore && !widget.isEditing)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _mirrorAsPersonal,
                    onChanged: (value) =>
                        setState(() => _mirrorAsPersonal = value),
                    title: const Text('Registrar também como entrada pessoal'),
                    subtitle: const Text(
                      'Assim o dinheiro aparece no seu controle pessoal.',
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saving || _loading ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Salvar'),
          ),
        ),
      ),
    );
  }
}

class _ProLaboreHint extends StatelessWidget {
  const _ProLaboreHint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pró-labore é o dinheiro que você tira do negócio para você. '
                'Ele reduz o caixa da empresa, mas não é despesa do negócio.',
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
