import '../../../core/utils/dates.dart';

enum DeadlineKind { das, dasn }

final class FiscalDeadline {
  const FiscalDeadline({
    required this.kind,
    required this.dueDate,
    required this.reference,
  });

  final DeadlineKind kind;
  final DateTime dueDate;
  final DateTime reference;

  String get competenceKey => Dates.competenceKey(reference);

  String get title => switch (kind) {
        DeadlineKind.das => 'DAS de ${Dates.monthYear(reference).toLowerCase()}',
        DeadlineKind.dasn =>
          'Declaração anual (DASN-SIMEI) de ${reference.year}',
      };

  @override
  bool operator ==(Object other) =>
      other is FiscalDeadline &&
      other.kind == kind &&
      other.dueDate == dueDate &&
      other.reference == reference;

  @override
  int get hashCode => Object.hash(kind, dueDate, reference);
}

final class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
}
