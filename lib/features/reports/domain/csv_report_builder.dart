import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../transactions/domain/transaction_enums.dart';
import 'report_data.dart';

abstract final class CsvReportBuilder {
  static const separator = ';';
  static const header = [
    'Data',
    'Tipo',
    'Escopo',
    'Categoria',
    'Descrição',
    'Forma de pagamento',
    'Cliente',
    'Valor',
  ];

  static String build(ReportData data) {
    final rows = <List<String>>[
      header,
      for (final t in data.sortedTransactions)
        [
          Dates.day(t.date),
          t.type.label,
          t.scope.label,
          t.type == TransactionType.proLabore ? '' : data.categoryName(t.categoryId),
          t.description,
          t.paymentMethod.label,
          data.customerName(t.customerId),
          Money.toDecimalString(t.signedAmountCents),
        ],
    ];
    return rows.map((row) => row.map(escape).join(separator)).join('\r\n');
  }

  static String escape(String value) {
    final needsQuotes = value.contains(separator) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
