import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/feedback.dart';
import '../../transactions/presentation/widgets/form_selectors.dart';
import 'charge_providers.dart';

class ChargeFormPage extends ConsumerStatefulWidget {
  const ChargeFormPage({super.key, this.initialCustomerId});

  final int? initialCustomerId;

  @override
  ConsumerState<ChargeFormPage> createState() => _ChargeFormPageState();
}

class _ChargeFormPageState extends ConsumerState<ChargeFormPage> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  late int? _customerId = widget.initialCustomerId;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ref.read(chargeServiceProvider).create(
          amountCents: AmountField.centsOf(_amount),
          description: _description.text,
          customerId: _customerId,
          dueDate: _dueDate,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok(:final value):
        context.pushReplacement(AppRoutes.charge(value));
      case Err(:final failure):
        showFailure(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova cobrança Pix')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AmountField(controller: _amount, autofocus: true, large: true),
          const SizedBox(height: 16),
          TextField(
            controller: _description,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'O que está cobrando? (opcional)',
              hintText: 'Ex.: Encomenda de doces',
            ),
          ),
          const SizedBox(height: 8),
          CustomerSelector(
            value: _customerId,
            onChanged: (id) => setState(() => _customerId = id),
          ),
          const SizedBox(height: 16),
          DateField(
            label: 'Vencimento (opcional)',
            value: _dueDate,
            allowClear: true,
            onChanged: (date) => setState(() => _dueDate = date),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Gerar QR Code'),
          ),
        ),
      ),
    );
  }
}
