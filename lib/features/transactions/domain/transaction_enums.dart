enum TransactionType { income, expense, proLabore }

enum TransactionScope { business, personal }

enum PaymentMethod { pix, cash, debitCard, creditCard, bankTransfer, boleto, other }

extension TransactionTypeLabel on TransactionType {
  String get label => switch (this) {
        TransactionType.income => 'Entrada',
        TransactionType.expense => 'Saída',
        TransactionType.proLabore => 'Pró-labore',
      };

  bool get isOutflow => this != TransactionType.income;
}

extension TransactionScopeLabel on TransactionScope {
  String get label => switch (this) {
        TransactionScope.business => 'Negócio',
        TransactionScope.personal => 'Pessoal',
      };
}

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.pix => 'Pix',
        PaymentMethod.cash => 'Dinheiro',
        PaymentMethod.debitCard => 'Débito',
        PaymentMethod.creditCard => 'Crédito',
        PaymentMethod.bankTransfer => 'Transferência',
        PaymentMethod.boleto => 'Boleto',
        PaymentMethod.other => 'Outro',
      };
}
