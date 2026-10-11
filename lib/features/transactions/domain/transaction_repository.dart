import '../../../core/result/result.dart';
import 'financial_transaction.dart';
import 'transaction_category.dart';
import 'transaction_filter.dart';

abstract interface class TransactionRepository {
  Stream<List<FinancialTransaction>> watch(TransactionFilter filter);

  Future<List<FinancialTransaction>> fetch(TransactionFilter filter);

  Future<FinancialTransaction?> findById(int id);

  Future<Result<int>> save(FinancialTransaction transaction);

  Future<Result<void>> saveAll(List<FinancialTransaction> transactions);

  Future<Result<void>> delete(int id);
}

abstract interface class CategoryRepository {
  Stream<List<TransactionCategory>> watchAll();

  Future<List<TransactionCategory>> fetchAll();

  Future<Result<int>> save(TransactionCategory category);

  Future<Result<void>> delete(int id);
}
