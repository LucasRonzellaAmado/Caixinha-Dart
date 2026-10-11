import '../../../core/result/result.dart';

abstract interface class DasPaymentRepository {
  Stream<Set<String>> watchPaidCompetences();

  Future<Result<void>> setPaid(String competence, {required bool paid});
}
