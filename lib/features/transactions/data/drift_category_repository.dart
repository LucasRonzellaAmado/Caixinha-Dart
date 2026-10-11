import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/mappers.dart';
import '../../../core/result/result.dart';
import '../domain/transaction_category.dart';
import '../domain/transaction_repository.dart';

class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$CategoriesTable, CategoryRow> get _all =>
      _db.select(_db.categories)
        ..orderBy([
          (c) => OrderingTerm.asc(c.type),
          (c) => OrderingTerm.asc(c.name),
        ]);

  @override
  Stream<List<TransactionCategory>> watchAll() =>
      _all.watch().map((rows) => rows.map((row) => row.toEntity()).toList());

  @override
  Future<List<TransactionCategory>> fetchAll() async {
    final rows = await _all.get();
    return rows.map((row) => row.toEntity()).toList();
  }

  @override
  Future<Result<int>> save(TransactionCategory category) {
    if (category.name.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Dê um nome para a categoria.')),
      );
    }
    return guardDatabase(() async {
      final id = category.id;
      final companion = category.copyWith(name: category.name.trim()).toCompanion();
      if (id == null) return _db.into(_db.categories).insert(companion);
      await (_db.update(_db.categories)..where((c) => c.id.equals(id)))
          .write(companion);
      return id;
    }, message: 'Não foi possível salvar a categoria.');
  }

  @override
  Future<Result<void>> delete(int id) => guardDatabase(
        () => (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go(),
        message: 'Não foi possível apagar a categoria.',
      );
}
