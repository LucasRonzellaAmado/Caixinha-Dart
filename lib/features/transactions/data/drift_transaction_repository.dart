import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/mappers.dart';
import '../../../core/result/result.dart';
import '../domain/financial_transaction.dart';
import '../domain/transaction_filter.dart';
import '../domain/transaction_repository.dart';

class DriftTransactionRepository implements TransactionRepository {
  DriftTransactionRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$TransactionsTable, TransactionRow> _query(
    TransactionFilter filter,
  ) {
    final start = filter.start;
    final end = filter.end;
    final type = filter.type;
    final scope = filter.scope;
    final categoryId = filter.categoryId;
    final customerId = filter.customerId;
    final search = filter.query.trim();

    return _db.select(_db.transactions)
      ..where((t) {
        final conditions = <Expression<bool>>[const Constant(true)];
        if (start != null) conditions.add(t.date.isBiggerOrEqualValue(start));
        if (end != null) conditions.add(t.date.isSmallerThanValue(end));
        if (type != null) conditions.add(t.type.equalsValue(type));
        if (scope != null) conditions.add(t.scope.equalsValue(scope));
        if (categoryId != null) conditions.add(t.categoryId.equals(categoryId));
        if (customerId != null) conditions.add(t.customerId.equals(customerId));
        if (search.isNotEmpty) {
          final pattern = '%$search%';
          conditions.add(t.description.like(pattern) | t.notes.like(pattern));
        }
        return conditions.reduce((a, b) => a & b);
      })
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.id),
      ]);
  }

  @override
  Stream<List<FinancialTransaction>> watch(TransactionFilter filter) =>
      _query(filter)
          .watch()
          .map((rows) => rows.map((row) => row.toEntity()).toList());

  @override
  Future<List<FinancialTransaction>> fetch(TransactionFilter filter) async {
    final rows = await _query(filter).get();
    return rows.map((row) => row.toEntity()).toList();
  }

  @override
  Future<FinancialTransaction?> findById(int id) async {
    final row = await (_db.select(_db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toEntity();
  }

  @override
  Future<Result<int>> save(FinancialTransaction transaction) =>
      guardDatabase(() => _write(transaction),
          message: 'Não foi possível salvar o lançamento.');

  @override
  Future<Result<void>> saveAll(List<FinancialTransaction> transactions) =>
      guardDatabase(
        () => _db.transaction(() async {
          for (final transaction in transactions) {
            await _write(transaction);
          }
        }),
        message: 'Não foi possível salvar os lançamentos.',
      );

  @override
  Future<Result<void>> delete(int id) => guardDatabase(
        () => (_db.delete(_db.transactions)..where((t) => t.id.equals(id)))
            .go(),
        message: 'Não foi possível apagar o lançamento.',
      );

  Future<int> _write(FinancialTransaction transaction) async {
    final id = transaction.id;
    if (id == null) {
      return _db.into(_db.transactions).insert(transaction.toCompanion());
    }
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
        .write(transaction.toCompanion());
    return id;
  }
}
