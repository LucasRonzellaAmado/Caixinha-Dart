import 'dart:convert';


import '../../../core/database/app_database.dart';
import '../../../core/database/mappers.dart';
import '../../../core/result/result.dart';
import '../../customers/domain/customer.dart';
import '../../pix/domain/charge.dart';
import '../../transactions/domain/financial_transaction.dart';
import '../../transactions/domain/transaction_category.dart';

class BackupService {
  BackupService(this._db);

  static const format = 'caixinha-backup';
  static const formatVersion = 1;

  final AppDatabase _db;

  Future<Map<String, Object?>> export() async {
    final categories = await _db.select(_db.categories).get();
    final customers = await _db.select(_db.customers).get();
    final transactions = await _db.select(_db.transactions).get();
    final charges = await _db.select(_db.charges).get();
    final dasPayments = await _db.select(_db.dasPayments).get();
    final settings = await _db.select(_db.settingsEntries).get();

    return {
      'format': format,
      'version': formatVersion,
      'schemaVersion': _db.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': [for (final row in categories) row.toEntity().toJson()],
      'customers': [for (final row in customers) row.toEntity().toJson()],
      'transactions': [for (final row in transactions) row.toEntity().toJson()],
      'charges': [for (final row in charges) row.toEntity().toJson()],
      'dasPayments': [
        for (final row in dasPayments)
          {
            'competence': row.competence,
            'paidAt': row.paidAt.toIso8601String(),
          },
      ],
      'settings': {for (final row in settings) row.key: row.value},
    };
  }

  String encode(Map<String, Object?> backup) =>
      const JsonEncoder.withIndent('  ').convert(backup);

  Future<Result<void>> restoreFromJson(String source) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error, stackTrace) {
      return Err(
        UnexpectedFailure(
          'O arquivo não é um backup válido.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
    if (decoded is! Map<String, dynamic>) {
      return const Err(ValidationFailure('O arquivo não é um backup válido.'));
    }
    return restore(decoded);
  }

  Future<Result<void>> restore(Map<String, dynamic> data) async {
    if (data['format'] != format) {
      return const Err(ValidationFailure('O arquivo não é um backup do Caixinha.'));
    }
    final version = data['version'];
    if (version is! int || version > formatVersion) {
      return const Err(
        ValidationFailure(
          'Esse backup é de uma versão mais nova do app. Atualize o Caixinha.',
        ),
      );
    }

    final _Snapshot snapshot;
    try {
      snapshot = _Snapshot.parse(data);
    } on Object catch (error, stackTrace) {
      return Err(
        UnexpectedFailure(
          'O backup está corrompido e não pôde ser lido.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }

    return guardDatabase(
      () => _db.transaction(() async {
        await _db.delete(_db.transactions).go();
        await _db.delete(_db.charges).go();
        await _db.delete(_db.dasPayments).go();
        await _db.delete(_db.customers).go();
        await _db.delete(_db.categories).go();
        await _db.delete(_db.settingsEntries).go();
        await _db.batch((batch) {
          batch
            ..insertAll(
              _db.categories,
              [for (final c in snapshot.categories) c.toCompanion()],
            )
            ..insertAll(
              _db.customers,
              [for (final c in snapshot.customers) c.toCompanion()],
            )
            ..insertAll(
              _db.transactions,
              [for (final t in snapshot.transactions) t.toCompanion()],
            )
            ..insertAll(
              _db.charges,
              [for (final c in snapshot.charges) c.toCompanion()],
            )
            ..insertAll(_db.dasPayments, [
              for (final (competence, paidAt) in snapshot.dasPayments)
                DasPaymentsCompanion.insert(
                  competence: competence,
                  paidAt: paidAt,
                ),
            ])
            ..insertAll(_db.settingsEntries, [
              for (final MapEntry(:key, :value) in snapshot.settings.entries)
                SettingsEntriesCompanion.insert(key: key, value: value),
            ]);
        });
      }),
      message: 'Não foi possível restaurar o backup.',
    );
  }
}

final class _Snapshot {
  const _Snapshot({
    required this.categories,
    required this.customers,
    required this.transactions,
    required this.charges,
    required this.dasPayments,
    required this.settings,
  });

  factory _Snapshot.parse(Map<String, dynamic> data) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final raw = data[key] as List<dynamic>? ?? const [];
      return [
        for (final item in raw)
          fromJson(Map<String, dynamic>.from(item as Map<dynamic, dynamic>)),
      ];
    }

    final settingsRaw = data['settings'] as Map<dynamic, dynamic>? ?? const {};
    return _Snapshot(
      categories: list('categories', TransactionCategory.fromJson),
      customers: list('customers', Customer.fromJson),
      transactions: list('transactions', FinancialTransaction.fromJson),
      charges: list('charges', Charge.fromJson),
      dasPayments: list(
        'dasPayments',
        (json) => (
          json['competence'] as String,
          DateTime.parse(json['paidAt'] as String),
        ),
      ),
      settings: {
        for (final entry in settingsRaw.entries)
          entry.key as String: entry.value as String,
      },
    );
  }

  final List<TransactionCategory> categories;
  final List<Customer> customers;
  final List<FinancialTransaction> transactions;
  final List<Charge> charges;
  final List<(String, DateTime)> dasPayments;
  final Map<String, String> settings;
}
