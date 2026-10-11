import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/dates.dart';

part 'charge.freezed.dart';
part 'charge.g.dart';

enum ChargeStatus { pending, received, canceled }

extension ChargeStatusLabel on ChargeStatus {
  String get label => switch (this) {
        ChargeStatus.pending => 'A receber',
        ChargeStatus.received => 'Recebida',
        ChargeStatus.canceled => 'Cancelada',
      };
}

@freezed
abstract class Charge with _$Charge {
  const Charge._();

  const factory Charge({
    int? id,
    int? customerId,
    required int amountCents,
    @Default('') String description,
    required String txid,
    @Default(ChargeStatus.pending) ChargeStatus status,
    required DateTime createdAt,
    DateTime? dueDate,
    DateTime? receivedAt,
    int? transactionId,
  }) = _Charge;

  factory Charge.fromJson(Map<String, dynamic> json) => _$ChargeFromJson(json);

  bool get isPending => status == ChargeStatus.pending;

  bool isOverdue(DateTime now) {
    final due = dueDate;
    return isPending && due != null && Dates.daysBetween(due, now) > 0;
  }

  int daysOpen(DateTime now) => Dates.daysBetween(createdAt, now);
}
