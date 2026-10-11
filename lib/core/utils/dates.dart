import 'package:intl/intl.dart';

abstract final class Dates {
  static DateFormat get _day => DateFormat('dd/MM/yyyy', 'pt_BR');
  static DateFormat get _dayMonth => DateFormat("d 'de' MMM", 'pt_BR');
  static DateFormat get _monthYear => DateFormat("MMMM 'de' y", 'pt_BR');
  static DateFormat get _shortMonth => DateFormat('MMM', 'pt_BR');
  static DateFormat get _weekday => DateFormat("EEEE, d 'de' MMMM", 'pt_BR');

  static String day(DateTime date) => _day.format(date);

  static String dayMonth(DateTime date) => _dayMonth.format(date);

  static String monthYear(DateTime date) => capitalize(_monthYear.format(date));

  static String shortMonth(DateTime date) =>
      capitalize(_shortMonth.format(date).replaceAll('.', ''));

  static String weekdayLong(DateTime date) =>
      capitalize(_weekday.format(date));

  static String capitalize(String text) =>
      text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime startOfMonth(DateTime date) => DateTime(date.year, date.month);

  static DateTime startOfNextMonth(DateTime date) =>
      DateTime(date.year, date.month + 1);

  static DateTime addMonths(DateTime date, int months) =>
      DateTime(date.year, date.month + months);

  static DateTime startOfYear(DateTime date) => DateTime(date.year);

  static int daysBetween(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String competenceKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  static String relativeDays(DateTime from, DateTime to) {
    final days = daysBetween(from, to);
    return switch (days) {
      0 => 'hoje',
      1 => 'amanhã',
      -1 => 'ontem',
      > 1 => 'em $days dias',
      _ => 'há ${-days} dias',
    };
  }
}
