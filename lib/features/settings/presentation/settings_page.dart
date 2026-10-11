import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/feedback.dart';
import '../../pix/domain/pix_key.dart';
import '../domain/app_settings.dart';
import 'settings_providers.dart';
import 'widgets/backup_section.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    AppSettings Function(AppSettings current) change,
  ) async {
    final result = await ref.read(settingsControllerProvider).update(change);
    if (!context.mounted) return;
    if (result case Err(:final failure)) showFailure(context, failure);
  }

  Future<void> _editText(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String initial,
    required AppSettings Function(AppSettings current, String value) apply,
    String? helper,
  }) async {
    final value = await askText(
      context,
      title: title,
      initialValue: initial,
      helper: helper,
    );
    if (value == null || !context.mounted) return;
    await _update(context, ref, (current) => apply(current, value));
  }

  Future<void> _editPixKey(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final type = await showDialog<PixKeyType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Tipo da chave Pix'),
        children: [
          for (final type in PixKeyType.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(type),
              child: Text(type.label),
            ),
        ],
      ),
    );
    if (type == null || !context.mounted) return;
    final raw = await askText(
      context,
      title: 'Chave Pix (${type.label})',
      initialValue: settings.pixKeyType == type ? settings.pixKey : '',
      hint: type.hint,
      keyboardType: switch (type) {
        PixKeyType.cpf || PixKeyType.cnpj => TextInputType.number,
        PixKeyType.phone => TextInputType.phone,
        PixKeyType.email => TextInputType.emailAddress,
        PixKeyType.random => TextInputType.text,
      },
    );
    if (raw == null || !context.mounted) return;
    switch (PixKey.normalize(type, raw)) {
      case Ok(:final value):
        await _update(
          context,
          ref,
          (current) => current.copyWith(pixKeyType: type, pixKey: value),
        );
      case Err(:final failure):
        showFailure(context, failure);
    }
  }

  Future<void> _editLimit(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final cents = await showDialog<int>(
      context: context,
      builder: (_) => _LimitDialog(initialCents: settings.meiAnnualLimitCents),
    );
    if (cents == null || cents <= 0 || !context.mounted) return;
    await _update(
      context,
      ref,
      (current) => current.copyWith(meiAnnualLimitCents: cents),
    );
  }

  Future<void> _editOpeningDate(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: settings.meiOpeningDate ?? now,
      firstDate: DateTime(2008),
      lastDate: now,
      helpText: 'Data de abertura do MEI',
    );
    if (date == null || !context.mounted) return;
    await _update(
      context,
      ref,
      (current) => current.copyWith(meiOpeningDate: date),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: AsyncValueView(
        value: ref.watch(settingsProvider),
        data: (settings) {
          String orDash(String value) => value.trim().isEmpty ? 'Não informado' : value;
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const SectionHeader('Seu negócio'),
              ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('Nome do negócio'),
                subtitle: Text(orDash(settings.businessName)),
                onTap: () => _editText(
                  context,
                  ref,
                  title: 'Nome do negócio',
                  initial: settings.businessName,
                  apply: (current, value) => current.copyWith(businessName: value),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Seu nome'),
                subtitle: Text(orDash(settings.ownerName)),
                onTap: () => _editText(
                  context,
                  ref,
                  title: 'Seu nome',
                  initial: settings.ownerName,
                  apply: (current, value) => current.copyWith(ownerName: value),
                ),
              ),
              const SectionHeader('Pix'),
              ListTile(
                leading: const Icon(Icons.key),
                title: const Text('Chave Pix'),
                subtitle: Text(
                  settings.hasPixKey
                      ? '${settings.pixKeyType.label}: ${settings.pixKey}'
                      : 'Não cadastrada',
                ),
                onTap: () => _editPixKey(context, ref, settings),
              ),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Nome que aparece no Pix'),
                subtitle: Text(orDash(settings.pixReceiverName)),
                onTap: () => _editText(
                  context,
                  ref,
                  title: 'Nome que aparece no Pix',
                  initial: settings.pixReceiverName,
                  helper: 'Até 25 letras, sem acentos fica melhor.',
                  apply: (current, value) =>
                      current.copyWith(pixMerchantName: value),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_city_outlined),
                title: const Text('Cidade'),
                subtitle: Text(orDash(settings.pixCity)),
                onTap: () => _editText(
                  context,
                  ref,
                  title: 'Cidade',
                  initial: settings.pixCity,
                  apply: (current, value) => current.copyWith(pixCity: value),
                ),
              ),
              const SectionHeader('MEI'),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Limite anual de faturamento'),
                subtitle: Text(Money.format(settings.meiAnnualLimitCents)),
                onTap: () => _editLimit(context, ref, settings),
              ),
              ListTile(
                leading: const Icon(Icons.event_available_outlined),
                title: const Text('Data de abertura do MEI'),
                subtitle: Text(
                  settings.meiOpeningDate == null
                      ? 'Não informada'
                      : Dates.day(settings.meiOpeningDate!),
                ),
                onTap: () => _editOpeningDate(context, ref, settings),
              ),
              const SectionHeader('Aparência'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<AppThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    for (final mode in AppThemeMode.values)
                      ButtonSegment(value: mode, label: Text(mode.label)),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) => _update(
                    context,
                    ref,
                    (current) => current.copyWith(themeMode: selection.first),
                  ),
                ),
              ),
              const SectionHeader('Backup e sincronização'),
              BackupSection(settings: settings),
            ],
          );
        },
      ),
    );
  }
}

class _LimitDialog extends StatefulWidget {
  const _LimitDialog({required this.initialCents});

  final int initialCents;

  @override
  State<_LimitDialog> createState() => _LimitDialogState();
}

class _LimitDialogState extends State<_LimitDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: AmountField.textFor(widget.initialCents));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Limite anual do MEI'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AmountField(controller: _controller, autofocus: true),
          const SizedBox(height: 8),
          const Text(
            'Use o valor que estiver em vigor. Se a lei mudar, é só '
            'atualizar aqui.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(AmountField.centsOf(_controller)),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
