import '../../../core/result/result.dart';
import 'charge.dart';

abstract interface class ChargeRepository {
  Stream<List<Charge>> watchAll({ChargeStatus? status, int? customerId});

  Stream<Charge?> watchById(int id);

  Future<List<Charge>> fetchAll();

  Future<Result<int>> create(Charge charge);

  Future<Result<void>> markAsReceived(
    Charge charge, {
    required DateTime receivedAt,
    int? categoryId,
  });

  Future<Result<void>> cancel(int id);
}
