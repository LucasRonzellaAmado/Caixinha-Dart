import '../../../core/fiscal/fiscal_rules.dart';
import '../../../core/utils/dates.dart';
import 'fiscal_deadline.dart';

class ReminderCalculator {
  const ReminderCalculator(this.rules);

  final FiscalRules rules;

  List<FiscalDeadline> upcomingDas(
    DateTime now, {
    int count = FiscalDefaults.upcomingDasCount,
  }) {
    final today = Dates.dateOnly(now);
    var competence = DateTime(today.year, today.month - 1);
    final result = <FiscalDeadline>[];
    while (result.length < count) {
      final due = rules.dasDueDate(competence);
      if (!due.isBefore(today)) {
        result.add(
          FiscalDeadline(
            kind: DeadlineKind.das,
            dueDate: due,
            reference: competence,
          ),
        );
      }
      competence = DateTime(competence.year, competence.month + 1);
    }
    return result;
  }

  FiscalDeadline nextDasn(DateTime now) {
    final today = Dates.dateOnly(now);
    var deadline = rules.dasnDeadline(today.year);
    if (deadline.isBefore(today)) deadline = rules.dasnDeadline(today.year + 1);
    return FiscalDeadline(
      kind: DeadlineKind.dasn,
      dueDate: deadline,
      reference: DateTime(deadline.year - 1),
    );
  }

  List<FiscalDeadline> upcoming(DateTime now) =>
      [...upcomingDas(now), nextDasn(now)]
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  List<ScheduledReminder> buildReminders({
    required DateTime now,
    required int daysBefore,
    required Set<String> paidCompetences,
    int hour = FiscalDefaults.reminderHour,
  }) {
    final deadlines = [
      ...upcomingDas(now).where(
        (deadline) => !paidCompetences.contains(deadline.competenceKey),
      ),
      nextDasn(now),
    ];
    final reminders = <ScheduledReminder>[];
    for (final deadline in deadlines) {
      final due = deadline.dueDate;
      final baseId = notificationBaseId(deadline);
      final beforeAt = DateTime(due.year, due.month, due.day - daysBefore, hour);
      final dueAt = DateTime(due.year, due.month, due.day, hour);
      if (daysBefore > 0 && beforeAt.isAfter(now)) {
        reminders.add(
          ScheduledReminder(
            id: baseId + 1,
            at: beforeAt,
            title: deadline.title,
            body: 'Vence em $daysBefore ${daysBefore == 1 ? 'dia' : 'dias'}, '
                'no dia ${Dates.day(due)}. Não deixe para a última hora!',
          ),
        );
      }
      if (dueAt.isAfter(now)) {
        reminders.add(
          ScheduledReminder(
            id: baseId + 2,
            at: dueAt,
            title: deadline.title,
            body: 'Vence hoje! Pague ou envie para evitar multa e juros.',
          ),
        );
      }
    }
    return reminders;
  }

  static int notificationBaseId(FiscalDeadline deadline) =>
      switch (deadline.kind) {
        DeadlineKind.das =>
          (deadline.reference.year * 100 + deadline.reference.month) * 10,
        DeadlineKind.dasn => (deadline.reference.year * 100 + 99) * 10,
      };
}
