import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/utils/dates.dart';
import '../data/drift_category_repository.dart';
import '../data/drift_transaction_repository.dart';
import '../domain/financial_transaction.dart';
import '../domain/transaction_category.dart';
import '../domain/transaction_enums.dart';
import '../domain/transaction_filter.dart';
import '../domain/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => DriftTransactionRepository(ref.watch(databaseProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => DriftCategoryRepository(ref.watch(databaseProvider)),
);

final categoriesProvider = StreamProvider<List<TransactionCategory>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

final categoriesByIdProvider = Provider<Map<int, TransactionCategory>>((ref) {
  final categories =
      ref.watch(categoriesProvider).value ?? const <TransactionCategory>[];
  return {
    for (final category in categories)
      if (category.id case final id?) id: category,
  };
});

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
  TransactionFilterNotifier.new,
);

class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => TransactionFilter.month(DateTime.now());

  DateTime get month => state.start ?? Dates.startOfMonth(DateTime.now());

  void previousMonth() => _shiftMonth(-1);

  void nextMonth() => _shiftMonth(1);

  void _shiftMonth(int delta) {
    final target = Dates.addMonths(month, delta);
    state = state.copyWith(
      start: Dates.startOfMonth(target),
      end: Dates.startOfNextMonth(target),
    );
  }

  void setScope(TransactionScope? scope) =>
      state = state.copyWith(scope: scope);

  void setType(TransactionType? type) => state = state.copyWith(
        type: type,
        categoryId: type == state.type ? state.categoryId : null,
      );

  void setCategory(int? categoryId) =>
      state = state.copyWith(categoryId: categoryId);

  void setQuery(String query) => state = state.copyWith(query: query);

  void clear() => state = TransactionFilter.month(month);
}

final filteredTransactionsProvider = StreamProvider<List<FinancialTransaction>>(
  (ref) => ref
      .watch(transactionRepositoryProvider)
      .watch(ref.watch(transactionFilterProvider)),
);

final transactionByIdProvider =
    FutureProvider.autoDispose.family<FinancialTransaction?, int>(
  (ref, id) => ref.watch(transactionRepositoryProvider).findById(id),
);

final customerTransactionsProvider =
    StreamProvider.autoDispose.family<List<FinancialTransaction>, int>(
  (ref, customerId) => ref
      .watch(transactionRepositoryProvider)
      .watch(TransactionFilter(customerId: customerId)),
);
