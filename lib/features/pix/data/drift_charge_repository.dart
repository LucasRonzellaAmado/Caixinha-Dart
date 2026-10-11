import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/mappers.dart';
import '../../../core/result/result.dart';
import '../../transactions/domain/financial_transaction.dart';
import '../../transactions/domain/transaction_enums.dart';
import '../domain/charge.dart';
import '../domain/charge_repository.dart';

class DriftChargeRepository implements ChargeRepository {
  DriftChargeRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Charge>> watchAll({ChargeStatus? status, int? customerId}) {
    final query = _db.select(_db.charges)
      ..where((c) {
        Expression<bool> condition = const Constant(true);
        if (status != null) condition = condition & c.status.equalsValue(status);
        if (customerId != null) {
          condition = condition & c.customerId.equals(customerId);
        }
        return condition;
      })
      ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]);
    return query
        .watch()
        .map((rows) => rows.map((row) => row.toEntity()).toList());
  }

  @override
  Stream<Charge?> watchById(int id) =>
      (_db.select(_db.charges)..where((c) => c.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row?.toEntity());

  @override
  Future<List<Charge>> fetchAll() async {
    final rows = await _db.select(_db.charges).get();
    return rows.map((row) => row.toEntity()).toList();
  }

  @override
  Future<Result<int>> create(Charge charge) => guardDatabase(
        () => _db.into(_db.charges).insert(charge.toCompanion()),
        message: 'Não foi possível criar a cobrança.',
      );

  @override
  Future<Result<void>> markAsReceived(
    Charge charge, {
    required DateTime receivedAt,
    int? categoryId,
  }) async {
    final chargeId = charge.id;
    if (chargeId == null) {
      return const Err(NotFoundFailure('Cobrança não encontrada.'));
    }
    return guardDatabase(
      () => _db.transaction(() async {
        final transactionId = await _db.into(_db.transactions).insert(
              FinancialTransaction(
                type: TransactionType.income,
                scope: TransactionScope.business,
                amountCents: charge.amountCents,
                date: receivedAt,
                categoryId: categoryId,
                paymentMethod: PaymentMethod.pix,
                customerId: charge.customerId,
                description: charge.description.isEmpty
                    ? 'Cobrança Pix'
                    : charge.description,
                chargeId: chargeId,
              ).toCompanion(),
            );
        await (_db.update(_db.charges)..where((c) => c.id.equals(chargeId)))
            .write(
          ChargesCompanion(
            status: const Value(ChargeStatus.received),
            receivedAt: Value(receivedAt),
            transactionId: Value(transactionId),
          ),
        );
      }),
      message: 'Não foi possível marcar a cobrança como recebida.',
    );
  }

  @override
  Future<Result<void>> cancel(int id) => guardDatabase(
        () => (_db.update(_db.charges)..where((c) => c.id.equals(id))).write(
          const ChargesCompanion(status: Value(ChargeStatus.canceled)),
        ),
        message: 'Não foi possível cancelar a cobrança.',
      );
}
