
import '../../../core/database/app_database.dart';
import '../../../core/result/result.dart';
import '../domain/das_payment_repository.dart';

class DriftDasPaymentRepository implements DasPaymentRepository {
  DriftDasPaymentRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<Set<String>> watchPaidCompetences() => _db
      .select(_db.dasPayments)
      .watch()
      .map((rows) => rows.map((row) => row.competence).toSet());

  @override
  Future<Result<void>> setPaid(String competence, {required bool paid}) =>
      guardDatabase(() async {
        if (paid) {
          await _db.into(_db.dasPayments).insertOnConflictUpdate(
                DasPaymentsCompanion.insert(
                  competence: competence,
                  paidAt: DateTime.now(),
                ),
              );
        } else {
          await (_db.delete(_db.dasPayments)
                ..where((d) => d.competence.equals(competence)))
              .go();
        }
      }, message: 'Não foi possível atualizar o DAS.');
}
