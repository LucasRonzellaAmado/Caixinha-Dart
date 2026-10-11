import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/mappers.dart';
import '../../../core/result/result.dart';
import '../domain/customer.dart';
import '../domain/customer_repository.dart';

class DriftCustomerRepository implements CustomerRepository {
  DriftCustomerRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$CustomersTable, CustomerRow> get _all =>
      _db.select(_db.customers)
        ..orderBy([(c) => OrderingTerm.asc(c.name.lower())]);

  @override
  Stream<List<Customer>> watchAll() =>
      _all.watch().map((rows) => rows.map((row) => row.toEntity()).toList());

  @override
  Stream<Customer?> watchById(int id) =>
      (_db.select(_db.customers)..where((c) => c.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row?.toEntity());

  @override
  Future<List<Customer>> fetchAll() async {
    final rows = await _all.get();
    return rows.map((row) => row.toEntity()).toList();
  }

  @override
  Future<Result<int>> save(Customer customer) {
    final name = customer.name.trim();
    if (name.isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Informe o nome do cliente.')),
      );
    }
    String? clean(String? value) =>
        value == null || value.trim().isEmpty ? null : value.trim();
    final normalized = customer.copyWith(
      name: name,
      phone: clean(customer.phone),
      document: clean(customer.document),
      notes: clean(customer.notes),
    );
    return guardDatabase(() async {
      final id = normalized.id;
      if (id == null) {
        return _db.into(_db.customers).insert(normalized.toCompanion());
      }
      await (_db.update(_db.customers)..where((c) => c.id.equals(id)))
          .write(normalized.toCompanion());
      return id;
    }, message: 'Não foi possível salvar o cliente.');
  }

  @override
  Future<Result<void>> delete(int id) => guardDatabase(
        () => (_db.delete(_db.customers)..where((c) => c.id.equals(id))).go(),
        message: 'Não foi possível apagar o cliente.',
      );
}
