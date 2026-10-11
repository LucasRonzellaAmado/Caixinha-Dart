import '../../../core/utils/dates.dart';
import '../../customers/domain/customer.dart';
import '../../transactions/domain/finance_calculator.dart';
import '../../transactions/domain/financial_transaction.dart';
import '../../transactions/domain/transaction_category.dart';
import '../../transactions/domain/transaction_enums.dart';

typedef ReportPeriod = ({DateTime start, DateTime end});

String periodLabel(ReportPeriod period) {
  final lastDay = period.end.subtract(const Duration(days: 1));
  return '${Dates.day(period.start)} a ${Dates.day(lastDay)}';
}

final class ReportData {
  const ReportData({
    required this.businessName,
    required this.period,
    required this.transactions,
    required this.categories,
    required this.customers,
    required this.generatedAt,
  });

  final String businessName;
  final ReportPeriod period;
  final List<FinancialTransaction> transactions;
  final Map<int, TransactionCategory> categories;
  final Map<int, Customer> customers;
  final DateTime generatedAt;

  List<FinancialTransaction> get sortedTransactions =>
      [...transactions]..sort((a, b) => a.date.compareTo(b.date));

  FinanceSummary get businessSummary => FinanceCalculator.summarize(
        transactions.where((t) => t.scope == TransactionScope.business),
      );

  FinanceSummary get personalSummary => FinanceCalculator.summarize(
        transactions.where((t) => t.scope == TransactionScope.personal),
      );

  List<CategoryTotal> businessTotals(TransactionType type) =>
      FinanceCalculator.totalsByCategory(
        transactions.where((t) => t.scope == TransactionScope.business),
        type,
      );

  String categoryName(int? id) =>
      categories[id]?.name ?? (id == null ? 'Sem categoria' : 'Removida');

  String customerName(int? id) => customers[id]?.name ?? '';
}
