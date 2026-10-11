import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/feedback.dart';
import '../../settings/presentation/settings_providers.dart';
import '../domain/fiscal_deadline.dart';
import 'reminder_providers.dart';

class RemindersPage extends ConsumerWidget {
  const RemindersPage({super.key});

  Future<void> _togglePaid(
    BuildContext context,
    WidgetRef ref,
    FiscalDeadline deadline, {
    required bool paid,
  }) async {
    final result = await ref
        .read(dasPaymentRepositoryProvider)
        .setPaid(deadline.competenceKey, paid: paid);
    if (!context.mounted) return;
    if (result case Err(:final failure)) showFailure(context, failure);
  }

  Future<void> _updateSettings(
    BuildContext context,
    WidgetRef ref, {
    bool? enabled,
    int? daysBefore,
  }) async {
    if (enabled == true) {
      await ref.read(notificationServiceProvider).requestPermission();
    }
    final result = await ref.read(settingsControllerProvider).update(
          (current) => current.copyWith(
            remindersEnabled: enabled ?? current.remindersEnabled,
            reminderDaysBefore: daysBefore ?? current.reminderDaysBefore,
          ),
        );
    if (!context.mounted) return;
    if (result case Err(:final failure)) showFailure(context, failure);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final deadlines = ref.watch(upcomingDeadlinesProvider);
    final paid = ref.watch(paidCompetencesProvider).value ?? const <String>{};
    final sync = ref.watch(reminderSyncProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Lembretes')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SwitchListTile(
            title: const Text('Avisar sobre DAS e declaração'),
            subtitle: const Text('Notificação no celular, mesmo sem internet.'),
            value: settings?.remindersEnabled ?? true,
            onChanged: (value) => _updateSettings(context, ref, enabled: value),
          ),
          ListTile(
            title: const Text('Avisar com antecedência de'),
            subtitle: Wrap(
              spacing: 8,
              children: [
                for (final days in const [1, 3, 5, 7])
                  ChoiceChip(
                    label: Text(days == 1 ? '1 dia' : '$days dias'),
                    selected: settings?.reminderDaysBefore == days,
                    onSelected: (_) =>
                        _updateSettings(context, ref, daysBefore: days),
                  ),
              ],
            ),
          ),
          if (sync case AsyncError(:final error))
            ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Não consegui agendar as notificações'),
              subtitle: Text('$error'),
            ),
          const SectionHeader('Próximos vencimentos'),
          for (final deadline in deadlines)
            _DeadlineTile(
              deadline: deadline,
              now: now,
              paid: paid.contains(deadline.competenceKey),
              onPaidChanged: deadline.kind == DeadlineKind.das
                  ? (value) => _togglePaid(context, ref, deadline, paid: value)
                  : null,
            ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'O DAS vence todo dia 20 (ou no próximo dia útil). '
              'A declaração anual (DASN-SIMEI) vai até 31 de maio. '
              'Você paga e declara pelo app MEI ou pelo Portal do Empreendedor.',
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineTile extends StatelessWidget {
  const _DeadlineTile({
    required this.deadline,
    required this.now,
    required this.paid,
    required this.onPaidChanged,
  });

  final FiscalDeadline deadline;
  final DateTime now;
  final bool paid;
  final ValueChanged<bool>? onPaidChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = onPaidChanged;
    return ListTile(
      leading: Icon(
        deadline.kind == DeadlineKind.das
            ? Icons.receipt_outlined
            : Icons.assignment_outlined,
      ),
      title: Text(deadline.title),
      subtitle: Text(
        '${Dates.day(deadline.dueDate)} • ${Dates.relativeDays(now, deadline.dueDate)}',
      ),
      trailing: onChanged == null
          ? null
          : FilterChip(
              label: Text(paid ? 'Pago' : 'Marcar pago'),
              selected: paid,
              onSelected: onChanged,
            ),
    );
  }
}
