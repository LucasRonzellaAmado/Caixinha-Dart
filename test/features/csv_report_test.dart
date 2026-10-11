import 'package:caixinha/features/customers/domain/customer.dart';
import 'package:caixinha/features/reports/domain/csv_report_builder.dart';
import 'package:caixinha/features/reports/domain/report_data.dart';
import 'package:caixinha/features/transactions/domain/financial_transaction.dart';
import 'package:caixinha/features/transactions/domain/transaction_category.dart';
import 'package:caixinha/features/transactions/domain/transaction_enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  test('gera CSV com separador ponto e vírgula e valores com sinal', () {
    final data = ReportData(
      businessName: 'Loja',
      period: (start: DateTime(2026, 9), end: DateTime(2026, 10)),
      generatedAt: DateTime(2026, 10, 2),
      categories: const {
        1: TransactionCategory(
          id: 1,
          name: 'Vendas',
          type: TransactionType.income,
          color: 0,
          iconKey: 'sell',
        ),
      },
      customers: const {2: Customer(id: 2, name: 'Ana; Silva')},
      transactions: [
        FinancialTransaction(
          type: TransactionType.expense,
          scope: TransactionScope.business,
          amountCents: 4500,
          date: DateTime(2026, 9, 10),
          description: 'Embalagens "kraft"',
          paymentMethod: PaymentMethod.cash,
        ),
        FinancialTransaction(
          type: TransactionType.income,
          scope: TransactionScope.business,
          amountCents: 123456,
          date: DateTime(2026, 9, 3),
          categoryId: 1,
          customerId: 2,
          description: 'Bolo',
        ),
      ],
    );

    final lines = CsvReportBuilder.build(data).split('\r\n');

    expect(lines, hasLength(3));
    expect(lines[0], CsvReportBuilder.header.join(';'));
    expect(
      lines[1],
      '03/09/2026;Entrada;Negócio;Vendas;Bolo;Pix;"Ana; Silva";1234,56',
    );
    expect(
      lines[2],
      '10/09/2026;Saída;Negócio;Sem categoria;"Embalagens ""kraft""";Dinheiro;;-45,00',
    );
    expect(periodLabel(data.period), '01/09/2026 a 30/09/2026');
  });
}
