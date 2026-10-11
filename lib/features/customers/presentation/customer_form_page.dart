import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/feedback.dart';
import '../domain/customer.dart';
import 'customer_providers.dart';

class CustomerFormPage extends ConsumerStatefulWidget {
  const CustomerFormPage({super.key, this.customerId});

  final int? customerId;

  @override
  ConsumerState<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends ConsumerState<CustomerFormPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _document = TextEditingController();
  final _notes = TextEditingController();
  late bool _loading = widget.customerId != null;
  bool _saving = false;

  bool get _isEditing => widget.customerId != null;

  @override
  void initState() {
    super.initState();
    final id = widget.customerId;
    if (id != null) _load(id);
  }

  Future<void> _load(int id) async {
    final customer =
        await ref.read(customerRepositoryProvider).watchById(id).first;
    if (!mounted) return;
    setState(() {
      _name.text = customer?.name ?? '';
      _phone.text = customer?.phone ?? '';
      _document.text = customer?.document ?? '';
      _notes.text = customer?.notes ?? '';
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _document.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ref.read(customerRepositoryProvider).save(
          Customer(
            id: widget.customerId,
            name: _name.text,
            phone: _phone.text,
            document: _document.text,
            notes: _notes.text,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok(:final value):
        if (_isEditing) {
          context.pop();
        } else {
          context.pushReplacement(AppRoutes.customer(value));
        }
      case Err(:final failure):
        showFailure(context, failure);
    }
  }

  Future<void> _delete() async {
    final id = widget.customerId;
    if (id == null) return;
    final confirmed = await confirm(
      context,
      title: 'Apagar cliente?',
      message: 'Os lançamentos e cobranças continuam salvos, sem o cliente.',
      confirmLabel: 'Apagar',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final result = await ref.read(customerRepositoryProvider).delete(id);
    if (!mounted) return;
    switch (result) {
      case Ok():
        context.go(AppRoutes.customers);
      case Err(:final failure):
        showFailure(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar cliente' : 'Novo cliente'),
        actions: [
          if (_isEditing)
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
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _name,
                  autofocus: !_isEditing,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp / telefone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _document,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CPF ou CNPJ (opcional)',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Observações'),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saving || _loading ? null : _save,
            icon: const Icon(Icons.check),
            label: const Text('Salvar'),
          ),
        ),
      ),
    );
  }
}
