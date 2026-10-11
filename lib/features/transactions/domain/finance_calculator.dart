import '../../../core/utils/dates.dart';
import 'financial_transaction.dart';
import 'transaction_enums.dart';

final class FinanceSummary {
  const FinanceSummary({
    required this.incomeCents,
    required this.expenseCents,
    required this.proLaboreCents,
  });

  static const empty =
      FinanceSummary(incomeCents: 0, expenseCents: 0, proLaboreCents: 0);

  final int incomeCents;
  final int expenseCents;
  final int proLaboreCents;

  int get profitCents => incomeCents - expenseCents;

  int get balanceCents => incomeCents - expenseCents - proLaboreCents;

  double get profitMargin =>
      incomeCents == 0 ? 0 : profitCents / incomeCents;
}

final class CategoryTotal {
  const CategoryTotal({required this.categoryId, required this.totalCents});

  final int? categoryId;
  final int totalCents;
}

final class MonthTotals {
  const MonthTotals({
    required this.month,
    required this.incomeCents,
    required this.expenseCents,
  });

  final DateTime month;
  final int incomeCents;
  final int expenseCents;

  int get resultCents => incomeCents - expenseCents;
}

abstract final class FinanceCalculator {
  static FinanceSummary summarize(Iterable<FinancialTransaction> transactions) {
    var income = 0;
    var expense = 0;
    var proLabore = 0;
    for (final transaction in transactions) {
      switch (transaction.type) {
        case TransactionType.income:
          income += transaction.amountCents;
        case TransactionType.expense:
          expense += transaction.amountCents;
        case TransactionType.proLabore:
          proLabore += transaction.amountCents;
      }
    }
    return FinanceSummary(
      incomeCents: income,
      expenseCents: expense,
      proLaboreCents: proLabore,
    );
  }

  static List<CategoryTotal> totalsByCategory(
    Iterable<FinancialTransaction> transactions,
    TransactionType type,
  ) {
    final totals = <int?, int>{};
    for (final transaction in transactions.where((t) => t.type == type)) {
      totals.update(
        transaction.categoryId,
        (value) => value + transaction.amountCents,
        ifAbsent: () => transaction.amountCents,
      );
    }
    final result = [
      for (final entry in totals.entries)
        CategoryTotal(categoryId: entry.key, totalCents: entry.value),
    ]..sort((a, b) => b.totalCents.compareTo(a.totalCents));
    return result;
  }

  static List<MonthTotals> monthlyEvolution(
    Iterable<FinancialTransaction> transactions, {
    required DateTime endMonth,
    int months = 6,
  }) {
    final firstMonth = Dates.addMonths(Dates.startOfMonth(endMonth), -(months - 1));
    final buckets = <String, (int, int)>{};
    for (final transaction in transactions) {
      final key = Dates.competenceKey(transaction.date);
      final (income, expense) = buckets[key] ?? (0, 0);
      buckets[key] = switch (transaction.type) {
        TransactionType.income => (income + transaction.amountCents, expense),
        TransactionType.expense => (income, expense + transaction.amountCents),
        TransactionType.proLabore => (income, expense),
      };
    }
    return [
      for (var i = 0; i < months; i++)
        _monthTotals(Dates.addMonths(firstMonth, i), buckets),
    ];
  }

  static MonthTotals _monthTotals(
    DateTime month,
    Map<String, (int, int)> buckets,
  ) {
    final (income, expense) = buckets[Dates.competenceKey(month)] ?? (0, 0);
    return MonthTotals(month: month, incomeCents: income, expenseCents: expense);
  }
}
