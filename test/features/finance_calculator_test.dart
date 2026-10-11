import 'package:caixinha/features/transactions/domain/finance_calculator.dart';
import 'package:caixinha/features/transactions/domain/financial_transaction.dart';
import 'package:caixinha/features/transactions/domain/transaction_enums.dart';
import 'package:caixinha/features/transactions/domain/transaction_filter.dart';
import 'package:flutter_test/flutter_test.dart';

FinancialTransaction tx(
  TransactionType type,
  int cents, {
  DateTime? date,
  int? categoryId,
  TransactionScope scope = TransactionScope.business,
  String description = '',
}) =>
    FinancialTransaction(
      type: type,
      scope: scope,
      amountCents: cents,
      date: date ?? DateTime(2026, 9, 10),
      categoryId: categoryId,
      description: description,
    );

void main() {
  group('FinanceCalculator.summarize', () {
    test('lista vazia gera tudo zero', () {
      final summary = FinanceCalculator.summarize(const []);
      expect(summary.incomeCents, 0);
      expect(summary.profitCents, 0);
      expect(summary.balanceCents, 0);
      expect(summary.profitMargin, 0);
    });

    test('lucro ignora pró-labore e saldo desconta pró-labore', () {
      final summary = FinanceCalculator.summarize([
        tx(TransactionType.income, 500000),
        tx(TransactionType.income, 150050),
        tx(TransactionType.expense, 120000),
        tx(TransactionType.proLabore, 200000),
      ]);
      expect(summary.incomeCents, 650050);
      expect(summary.expenseCents, 120000);
      expect(summary.proLaboreCents, 200000);
      expect(summary.profitCents, 530050);
      expect(summary.balanceCents, 330050);
    });

    test('prejuízo fica negativo', () {
      final summary = FinanceCalculator.summarize([
        tx(TransactionType.income, 1000),
        tx(TransactionType.expense, 2500),
      ]);
      expect(summary.profitCents, -1500);
    });
  });

  test('totalsByCategory soma e ordena do maior para o menor', () {
    final totals = FinanceCalculator.totalsByCategory([
      tx(TransactionType.expense, 1000, categoryId: 1),
      tx(TransactionType.expense, 5000, categoryId: 2),
      tx(TransactionType.expense, 2000, categoryId: 1),
      tx(TransactionType.expense, 700),
      tx(TransactionType.income, 9999, categoryId: 3),
    ], TransactionType.expense);
    expect(totals.map((t) => (t.categoryId, t.totalCents)).toList(), [
      (2, 5000),
      (1, 3000),
      (null, 700),
    ]);
  });

  test('monthlyEvolution preenche meses sem movimento', () {
    final months = FinanceCalculator.monthlyEvolution(
      [
        tx(TransactionType.income, 1000, date: DateTime(2026, 7, 3)),
        tx(TransactionType.expense, 400, date: DateTime(2026, 7, 20)),
        tx(TransactionType.income, 3000, date: DateTime(2026, 9, 1)),
        tx(TransactionType.proLabore, 999, date: DateTime(2026, 9, 2)),
      ],
      endMonth: DateTime(2026, 9, 15),
      months: 3,
    );
    expect(months.map((m) => m.month).toList(), [
      DateTime(2026, 7),
      DateTime(2026, 8),
      DateTime(2026, 9),
    ]);
    expect(months[0].resultCents, 600);
    expect(months[1].incomeCents, 0);
    expect(months[2].expenseCents, 0);
    expect(months[2].incomeCents, 3000);
  });

  test('TransactionFilter.matches respeita período, tipo e busca', () {
    final filter = TransactionFilter.month(DateTime(2026, 9)).copyWith(
      type: TransactionType.income,
      query: 'bolo',
    );
    expect(
      filter.matches(tx(TransactionType.income, 1, description: 'Bolo de pote')),
      isTrue,
    );
    expect(
      filter.matches(tx(TransactionType.expense, 1, description: 'Bolo')),
      isFalse,
    );
    expect(
      filter.matches(
        tx(
          TransactionType.income,
          1,
          description: 'Bolo',
          date: DateTime(2026, 10, 1),
        ),
      ),
      isFalse,
    );
  });
}
