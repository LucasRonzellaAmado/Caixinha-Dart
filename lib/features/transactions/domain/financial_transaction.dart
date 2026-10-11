import 'package:freezed_annotation/freezed_annotation.dart';

import 'transaction_enums.dart';

part 'financial_transaction.freezed.dart';
part 'financial_transaction.g.dart';

@freezed
abstract class FinancialTransaction with _$FinancialTransaction {
  const FinancialTransaction._();

  const factory FinancialTransaction({
    int? id,
    required TransactionType type,
    required TransactionScope scope,
    required int amountCents,
    required DateTime date,
    int? categoryId,
    @Default(PaymentMethod.pix) PaymentMethod paymentMethod,
    int? customerId,
    @Default('') String description,
    String? notes,
    int? chargeId,
  }) = _FinancialTransaction;

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) =>
      _$FinancialTransactionFromJson(json);

  int get signedAmountCents =>
      type == TransactionType.income ? amountCents : -amountCents;
}
