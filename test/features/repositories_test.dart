import 'package:caixinha/core/database/app_database.dart';
import 'package:caixinha/features/customers/data/drift_customer_repository.dart';
import 'package:caixinha/features/customers/domain/customer.dart';
import 'package:caixinha/features/pix/data/drift_charge_repository.dart';
import 'package:caixinha/features/pix/domain/charge.dart';
import 'package:caixinha/features/settings/data/backup_service.dart';
import 'package:caixinha/features/settings/data/drift_settings_repository.dart';
import 'package:caixinha/features/settings/domain/app_settings.dart';
import 'package:caixinha/features/transactions/data/drift_category_repository.dart';
import 'package:caixinha/features/transactions/data/drift_transaction_repository.dart';
import 'package:caixinha/features/transactions/domain/financial_transaction.dart';
import 'package:caixinha/features/transactions/domain/transaction_enums.dart';
import 'package:caixinha/features/transactions/domain/transaction_filter.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftTransactionRepository transactions;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    transactions = DriftTransactionRepository(db);
  });

  tearDown(() => db.close());

  FinancialTransaction tx(
    TransactionType type,
    int cents,
    DateTime date, {
    TransactionScope scope = TransactionScope.business,
    String description = '',
  }) =>
      FinancialTransaction(
        type: type,
        scope: scope,
        amountCents: cents,
        date: date,
        description: description,
      );

  test('cria categorias padrão na primeira abertura', () async {
    final categories = await DriftCategoryRepository(db).fetchAll();
    expect(categories, isNotEmpty);
    expect(categories.any((c) => c.type == TransactionType.income), isTrue);
    expect(categories.any((c) => c.type == TransactionType.expense), isTrue);
  });

  test('salva, filtra, edita e apaga lançamentos', () async {
    await transactions.saveAll([
      tx(TransactionType.income, 1000, DateTime(2026, 9, 5), description: 'Bolo'),
      tx(TransactionType.expense, 300, DateTime(2026, 9, 6)),
      tx(TransactionType.income, 999, DateTime(2026, 10, 1)),
      tx(
        TransactionType.expense,
        50,
        DateTime(2026, 9, 7),
        scope: TransactionScope.personal,
      ),
    ]);

    final september = await transactions.fetch(
      TransactionFilter.month(DateTime(2026, 9), scope: TransactionScope.business),
    );
    expect(september.map((t) => t.amountCents), [300, 1000]);

    final search = await transactions.fetch(const TransactionFilter(query: 'bol'));
    expect(search.single.description, 'Bolo');

    final id = search.single.id!;
    await transactions.save(search.single.copyWith(amountCents: 1200));
    expect((await transactions.findById(id))?.amountCents, 1200);

    await transactions.delete(id);
    expect(await transactions.findById(id), isNull);
  });

  test('receber cobrança cria entrada do negócio ligada à cobrança', () async {
    final customerId =
        (await DriftCustomerRepository(db).save(const Customer(name: 'Ana')))
            .valueOrNull!;
    final charges = DriftChargeRepository(db);
    final chargeId = (await charges.create(
      Charge(
        customerId: customerId,
        amountCents: 4590,
        txid: 'CX1',
        createdAt: DateTime(2026, 10, 1),
      ),
    ))
        .valueOrNull!;
    final charge = (await charges.watchById(chargeId).first)!;

    final result =
        await charges.markAsReceived(charge, receivedAt: DateTime(2026, 10, 2));
    expect(result.isOk, isTrue);

    final updated = (await charges.watchById(chargeId).first)!;
    expect(updated.status, ChargeStatus.received);
    final income = await transactions.findById(updated.transactionId!);
    expect(income?.amountCents, 4590);
    expect(income?.customerId, customerId);
    expect(income?.chargeId, chargeId);
    expect(income?.scope, TransactionScope.business);
    expect(income?.paymentMethod, PaymentMethod.pix);
  });

  test('configurações começam com padrão e persistem', () async {
    final settings = DriftSettingsRepository(db);
    expect(await settings.load(), const AppSettings());
    await settings.save(const AppSettings(businessName: 'Doces da Ana'));
    expect((await settings.load()).businessName, 'Doces da Ana');
  });

  test('backup exporta e restaura tudo', () async {
    await transactions.save(tx(TransactionType.income, 777, DateTime(2026, 9, 1)));
    await DriftSettingsRepository(db)
        .save(const AppSettings(businessName: 'Loja', onboardingCompleted: true));
    final backup = BackupService(db);
    final json = backup.encode(await backup.export());

    await transactions.save(tx(TransactionType.expense, 1, DateTime(2026, 9, 2)));
    final restored = await backup.restoreFromJson(json);
    expect(restored.isOk, isTrue);

    final all = await transactions.fetch(const TransactionFilter());
    expect(all.single.amountCents, 777);
    expect((await DriftSettingsRepository(db).load()).businessName, 'Loja');
  });

  test('backup inválido é recusado sem apagar dados', () async {
    await transactions.save(tx(TransactionType.income, 10, DateTime(2026, 9, 1)));
    final backup = BackupService(db);
    expect((await backup.restoreFromJson('{"format":"outro"}')).isOk, isFalse);
    expect((await backup.restoreFromJson('não é json')).isOk, isFalse);
    expect(await transactions.fetch(const TransactionFilter()), hasLength(1));
  });
}
