import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fiscal/fiscal_rules.dart';
import '../../../core/result/result.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/feedback.dart';
import '../../pix/domain/pix_key.dart';
import '../../reminders/presentation/reminder_providers.dart';
import '../../settings/presentation/settings_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _businessName = TextEditingController();
  final _ownerName = TextEditingController();
  final _pixKey = TextEditingController();
  final _city = TextEditingController();
  final _limit = TextEditingController(
    text: AmountField.textFor(FiscalDefaults.meiAnnualLimitCents),
  );
  PixKeyType _pixKeyType = PixKeyType.cpf;
  DateTime? _openingDate;
  bool _saving = false;

  @override
  void dispose() {
    _businessName.dispose();
    _ownerName.dispose();
    _pixKey.dispose();
    _city.dispose();
    _limit.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final businessName = _businessName.text.trim();
    if (businessName.isEmpty) {
      showMessage(context, 'Conte pra gente o nome do seu negócio.');
      return;
    }
    var pixKey = '';
    if (_pixKey.text.trim().isNotEmpty) {
      switch (PixKey.normalize(_pixKeyType, _pixKey.text)) {
        case Ok(:final value):
          pixKey = value;
        case Err(:final failure):
          showFailure(context, failure);
          return;
      }
    }
    final limit = AmountField.centsOf(_limit);

    setState(() => _saving = true);
    await ref.read(notificationServiceProvider).requestPermission();
    final result = await ref.read(settingsControllerProvider).update(
          (current) => current.copyWith(
            onboardingCompleted: true,
            businessName: businessName,
            ownerName: _ownerName.text.trim(),
            pixKeyType: _pixKeyType,
            pixKey: pixKey,
            pixMerchantName: businessName,
            pixCity: _city.text.trim(),
            meiAnnualLimitCents:
                limit > 0 ? limit : FiscalDefaults.meiAnnualLimitCents,
            meiOpeningDate: _openingDate,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result case Err(:final failure)) showFailure(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gap = SizedBox(height: 16);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.savings_outlined, size: 64, color: theme.colorScheme.primary),
            gap,
            Text(
              'Bem-vindo ao Caixinha!',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Em 1 minuto você deixa tudo pronto para separar o dinheiro do '
              'negócio do pessoal, acompanhar o limite do MEI e cobrar com Pix.',
              textAlign: TextAlign.center,
            ),
            const SectionHeader('Seu negócio'),
            TextField(
              controller: _businessName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome do negócio',
                hintText: 'Ex.: Doces da Ana',
              ),
            ),
            gap,
            TextField(
              controller: _ownerName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Seu nome'),
            ),
            gap,
            DateField(
              label: 'Data de abertura do MEI (opcional)',
              value: _openingDate,
              allowClear: true,
              onChanged: (date) => setState(() => _openingDate = date),
            ),
            gap,
            AmountField(controller: _limit, label: 'Limite anual do MEI'),
            const Padding(
              padding: EdgeInsets.only(top: 4, left: 12),
              child: Text(
                'Já vem com o valor atual. Se a lei mudar, você altera nas configurações.',
              ),
            ),
            const SectionHeader('Pix (pode deixar para depois)'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in PixKeyType.values)
                  ChoiceChip(
                    label: Text(type.label),
                    selected: type == _pixKeyType,
                    onSelected: (_) => setState(() => _pixKeyType = type),
                  ),
              ],
            ),
            gap,
            TextField(
              controller: _pixKey,
              decoration: InputDecoration(
                labelText: 'Chave Pix',
                hintText: _pixKeyType.hint,
              ),
            ),
            gap,
            TextField(
              controller: _city,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Cidade'),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _finish,
              child: const Text('Começar a usar'),
            ),
          ],
        ),
      ),
    );
  }
}
