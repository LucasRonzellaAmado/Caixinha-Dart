import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fiscal/fiscal_providers.dart';
import '../../../core/utils/dates.dart';
import '../../transactions/domain/finance_calculator.dart';
import '../../transactions/domain/financial_transaction.dart';
import '../../transactions/domain/transaction_enums.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/presentation/transaction_providers.dart';

final dashboardScopeProvider =
    NotifierProvider<DashboardScopeNotifier, TransactionScope>(
  DashboardScopeNotifier.new,
);

class DashboardScopeNotifier extends Notifier<TransactionScope> {
  @override
  TransactionScope build() => TransactionScope.business;

  void select(TransactionScope scope) => state = scope;
}

final dashboardMonthTransactionsProvider =
    StreamProvider<List<FinancialTransaction>>((ref) {
  final now = ref.watch(clockProvider)();
  final scope = ref.watch(dashboardScopeProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .watch(TransactionFilter.month(now, scope: scope));
});

final dashboardSummaryProvider = FutureProvider<FinanceSummary>((ref) async {
  final transactions =
      await ref.watch(dashboardMonthTransactionsProvider.future);
  return FinanceCalculator.summarize(transactions);
});

final dashboardBalanceProvider = StreamProvider<int>((ref) {
  final scope = ref.watch(dashboardScopeProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .watch(TransactionFilter(scope: scope))
      .map((transactions) =>
          FinanceCalculator.summarize(transactions).balanceCents);
});

final dashboardEvolutionProvider = StreamProvider<List<MonthTotals>>((ref) {
  final now = ref.watch(clockProvider)();
  final scope = ref.watch(dashboardScopeProvider);
  const months = 6;
  return ref
      .watch(transactionRepositoryProvider)
      .watch(
        TransactionFilter(
          start: Dates.addMonths(Dates.startOfMonth(now), -(months - 1)),
          end: Dates.startOfNextMonth(now),
          scope: scope,
        ),
      )
      .map(
        (transactions) => FinanceCalculator.monthlyEvolution(
          transactions,
          endMonth: now,
          months: months,
        ),
      );
});

final dashboardExpenseByCategoryProvider =
    FutureProvider<List<CategoryTotal>>((ref) async {
  final transactions =
      await ref.watch(dashboardMonthTransactionsProvider.future);
  return FinanceCalculator.totalsByCategory(
    transactions,
    TransactionType.expense,
  );
});
