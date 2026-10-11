abstract final class FiscalDefaults {
  static const int meiAnnualLimitCents = 8100000;
  static const int dasDueDay = 20;
  static const int dasnDeadlineMonth = 5;
  static const int dasnDeadlineDay = 31;
  static const int reminderDaysBefore = 3;
  static const int reminderHour = 9;
  static const int upcomingDasCount = 12;
  static const double attentionThreshold = 0.7;
  static const double dangerThreshold = 0.9;
  static const double toleranceThreshold = 1.2;
}

final class FiscalRules {
  const FiscalRules({
    this.dasDueDay = FiscalDefaults.dasDueDay,
    this.dasnDeadlineMonth = FiscalDefaults.dasnDeadlineMonth,
    this.dasnDeadlineDay = FiscalDefaults.dasnDeadlineDay,
    this.attentionThreshold = FiscalDefaults.attentionThreshold,
    this.dangerThreshold = FiscalDefaults.dangerThreshold,
    this.toleranceThreshold = FiscalDefaults.toleranceThreshold,
  });

  final int dasDueDay;
  final int dasnDeadlineMonth;
  final int dasnDeadlineDay;
  final double attentionThreshold;
  final double dangerThreshold;
  final double toleranceThreshold;

  int effectiveAnnualLimit({
    required int annualLimitCents,
    required int year,
    DateTime? openingDate,
  }) {
    if (openingDate == null || openingDate.year != year) {
      return annualLimitCents;
    }
    final activeMonths = 12 - openingDate.month + 1;
    return annualLimitCents * activeMonths ~/ 12;
  }

  DateTime dasDueDate(DateTime competence) => nextBusinessDay(
        DateTime(competence.year, competence.month + 1, dasDueDay),
      );

  DateTime dasnDeadline(int year) =>
      DateTime(year, dasnDeadlineMonth, dasnDeadlineDay);

  DateTime nextBusinessDay(DateTime date) {
    var current = DateTime(date.year, date.month, date.day);
    while (!isBusinessDay(current)) {
      current = DateTime(current.year, current.month, current.day + 1);
    }
    return current;
  }

  bool isBusinessDay(DateTime date) =>
      date.weekday != DateTime.saturday &&
      date.weekday != DateTime.sunday &&
      !BankHolidays.isHoliday(date);
}

abstract final class BankHolidays {
  static final Set<(int, int)> _fixed = {
    (1, 1),
    (4, 21),
    (5, 1),
    (9, 7),
    (10, 12),
    (11, 2),
    (11, 15),
    (11, 20),
    (12, 25),
  };

  static bool isHoliday(DateTime date) {
    if (_fixed.contains((date.month, date.day))) return true;
    return movableHolidays(date.year).any(
      (holiday) => holiday.month == date.month && holiday.day == date.day,
    );
  }

  static List<DateTime> movableHolidays(int year) {
    final easter = easterSunday(year);
    DateTime offset(int days) =>
        DateTime(easter.year, easter.month, easter.day + days);
    return [offset(-48), offset(-47), offset(-2), offset(60)];
  }

  static DateTime easterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }
}
