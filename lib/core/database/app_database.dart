import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/pix/domain/charge.dart';
import '../../features/transactions/domain/transaction_enums.dart';
import 'seed.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Categories,
    Customers,
    Transactions,
    Charges,
    DasPayments,
    SettingsEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'caixinha'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
          await batch(
            (batch) => batch.insertAll(categories, defaultCategories()),
          );
        },
        onUpgrade: (migrator, from, to) async {
          for (var version = from; version < to; version++) {
            await _upgradeFrom(migrator, version);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _upgradeFrom(Migrator migrator, int version) async {
    throw UnsupportedError(
      'Não existe migração a partir da versão $version do banco.',
    );
  }
}
