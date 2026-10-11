import 'package:caixinha/core/fiscal/fiscal_rules.dart';
import 'package:caixinha/features/reminders/domain/fiscal_deadline.dart';
import 'package:caixinha/features/reminders/domain/reminder_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  const calculator = ReminderCalculator(FiscalRules());

  setUpAll(() => initializeDateFormatting('pt_BR'));

  test('próximos DAS a partir de 2 de outubro', () {
    final das = calculator.upcomingDas(DateTime(2026, 10, 2), count: 3);
    expect(das.map((d) => d.dueDate).toList(), [
      DateTime(2026, 10, 20),
      DateTime(2026, 11, 23),
      DateTime(2026, 12, 21),
    ]);
    expect(das.first.competenceKey, '2026-09');
  });

  test('depois do dia 20 pula para o próximo mês', () {
    final das = calculator.upcomingDas(DateTime(2026, 10, 21), count: 1);
    expect(das.single.reference, DateTime(2026, 10));
  });

  test('no próprio dia do vencimento ainda aparece', () {
    final das = calculator.upcomingDas(DateTime(2026, 10, 20, 18), count: 1);
    expect(das.single.dueDate, DateTime(2026, 10, 20));
  });

  test('DASN vence 31 de maio e vira o ano depois do prazo', () {
    expect(
      calculator.nextDasn(DateTime(2026, 3, 1)).dueDate,
      DateTime(2026, 5, 31),
    );
    final next = calculator.nextDasn(DateTime(2026, 6, 1));
    expect(next.dueDate, DateTime(2027, 5, 31));
    expect(next.reference.year, 2026);
  });

  test('gera avisos antes e no dia, pulando DAS pago e horários passados', () {
    final reminders = calculator.buildReminders(
      now: DateTime(2026, 10, 18, 10),
      daysBefore: 3,
      paidCompetences: {'2026-10'},
    );
    final first = reminders.where(
      (r) => r.id ~/ 10 == 202609,
    );
    expect(first.map((r) => r.at).toList(), [DateTime(2026, 10, 20, 9)]);
    expect(reminders.where((r) => r.id ~/ 10 == 202610), isEmpty);
    expect(
      reminders.any((r) => r.at == DateTime(2026, 12, 18, 9)),
      isTrue,
    );
    expect(reminders.every((r) => r.at.isAfter(DateTime(2026, 10, 18, 10))),
        isTrue);
  });

  test('ids de notificação são únicos', () {
    final reminders = calculator.buildReminders(
      now: DateTime(2026, 1, 1),
      daysBefore: 5,
      paidCompetences: const {},
    );
    expect(reminders.map((r) => r.id).toSet().length, reminders.length);
    expect(
      ReminderCalculator.notificationBaseId(
        FiscalDeadline(
          kind: DeadlineKind.dasn,
          dueDate: DateTime(2027, 5, 31),
          reference: DateTime(2026),
        ),
      ),
      2026990,
    );
  });
}
