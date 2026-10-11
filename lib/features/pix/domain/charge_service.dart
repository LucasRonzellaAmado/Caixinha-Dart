import '../../../core/result/result.dart';
import 'charge.dart';
import 'charge_repository.dart';

class ChargeService {
  ChargeService(this._repository, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final ChargeRepository _repository;
  final DateTime Function() _clock;

  Future<Result<int>> create({
    required int amountCents,
    String description = '',
    int? customerId,
    DateTime? dueDate,
  }) async {
    if (amountCents <= 0) {
      return const Err(ValidationFailure('Informe um valor maior que zero.'));
    }
    final now = _clock();
    return _repository.create(
      Charge(
        customerId: customerId,
        amountCents: amountCents,
        description: description.trim(),
        txid: generateTxid(now),
        createdAt: now,
        dueDate: dueDate,
      ),
    );
  }

  Future<Result<void>> receive(Charge charge, {int? categoryId}) async {
    if (!charge.isPending) {
      return Err(
        ValidationFailure(
          'Essa cobrança já está como "${charge.status.label.toLowerCase()}".',
        ),
      );
    }
    return _repository.markAsReceived(
      charge,
      receivedAt: _clock(),
      categoryId: categoryId,
    );
  }

  Future<Result<void>> cancel(Charge charge) async {
    final id = charge.id;
    if (id == null || !charge.isPending) {
      return const Err(
        ValidationFailure('Só dá para cancelar cobranças em aberto.'),
      );
    }
    return _repository.cancel(id);
  }

  static String generateTxid(DateTime now) =>
      'CX${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
}
