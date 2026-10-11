import 'package:intl/intl.dart';

abstract final class Money {
  static final NumberFormat _grouping = NumberFormat.decimalPattern('pt_BR');
  static final NumberFormat _compact = NumberFormat.compact(locale: 'pt_BR');

  static String format(int cents, {bool symbol = true}) {
    final negative = cents < 0;
    final abs = cents.abs();
    final reais = _grouping.format(abs ~/ 100);
    final centavos = (abs % 100).toString().padLeft(2, '0');
    final value = '$reais,$centavos';
    final text = symbol ? 'R\$ $value' : value;
    return negative ? '-$text' : text;
  }

  static String formatSigned(int cents) =>
      cents > 0 ? '+${format(cents)}' : format(cents);

  static String formatCompact(int cents) =>
      'R\$ ${_compact.format(cents ~/ 100)}';

  static String toPixAmount(int cents) {
    final abs = cents.abs();
    return '${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }

  static String toDecimalString(int cents) {
    final negative = cents < 0;
    final abs = cents.abs();
    final text = '${abs ~/ 100},${(abs % 100).toString().padLeft(2, '0')}';
    return negative ? '-$text' : text;
  }

  static int fromDigits(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 0;
    return int.parse(digits);
  }

  static int? parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9,\-]'), '');
    if (cleaned.isEmpty || cleaned == '-') return null;
    final negative = cleaned.startsWith('-');
    final unsigned = cleaned.replaceAll('-', '');
    final parts = unsigned.split(',');
    if (parts.length > 2) return null;
    final reais = int.tryParse(parts[0].isEmpty ? '0' : parts[0]);
    if (reais == null) return null;
    var centavos = 0;
    if (parts.length == 2) {
      final decimals = parts[1];
      if (decimals.isEmpty || decimals.length > 2) return null;
      centavos = int.parse(decimals.padRight(2, '0'));
    }
    final total = reais * 100 + centavos;
    return negative ? -total : total;
  }
}
