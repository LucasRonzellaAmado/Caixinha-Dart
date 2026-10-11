import 'package:drift/drift.dart';

import '../../features/customers/domain/customer.dart';
import '../../features/pix/domain/charge.dart';
import '../../features/transactions/domain/financial_transaction.dart';
import '../../features/transactions/domain/transaction_category.dart';
import 'app_database.dart';

Value<int> _id(int? id) => id == null ? const Value.absent() : Value(id);

extension CategoryRowMapper on CategoryRow {
  TransactionCategory toEntity() => TransactionCategory(
        id: id,
        name: name,
        type: type,
        color: color,
        iconKey: iconKey,
        archived: archived,
      );
}

extension TransactionCategoryMapper on TransactionCategory {
  CategoriesCompanion toCompanion() => CategoriesCompanion(
        id: _id(id),
        name: Value(name),
        type: Value(type),
        color: Value(color),
        iconKey: Value(iconKey),
        archived: Value(archived),
      );
}

extension TransactionRowMapper on TransactionRow {
  FinancialTransaction toEntity() => FinancialTransaction(
        id: id,
        type: type,
        scope: scope,
        amountCents: amountCents,
        date: date,
        categoryId: categoryId,
        paymentMethod: paymentMethod,
        customerId: customerId,
        description: description,
        notes: notes,
        chargeId: chargeId,
      );
}

extension FinancialTransactionMapper on FinancialTransaction {
  TransactionsCompanion toCompanion() => TransactionsCompanion(
        id: _id(id),
        type: Value(type),
        scope: Value(scope),
        amountCents: Value(amountCents),
        date: Value(date),
        categoryId: Value(categoryId),
        paymentMethod: Value(paymentMethod),
        customerId: Value(customerId),
        description: Value(description),
        notes: Value(notes),
        chargeId: Value(chargeId),
      );
}

extension CustomerRowMapper on CustomerRow {
  Customer toEntity() => Customer(
        id: id,
        name: name,
        phone: phone,
        document: document,
        notes: notes,
      );
}

extension CustomerMapper on Customer {
  CustomersCompanion toCompanion() => CustomersCompanion(
        id: _id(id),
        name: Value(name),
        phone: Value(phone),
        document: Value(document),
        notes: Value(notes),
      );
}

extension ChargeRowMapper on ChargeRow {
  Charge toEntity() => Charge(
        id: id,
        customerId: customerId,
        amountCents: amountCents,
        description: description,
        txid: txid,
        status: status,
        createdAt: createdAt,
        dueDate: dueDate,
        receivedAt: receivedAt,
        transactionId: transactionId,
      );
}

extension ChargeMapper on Charge {
  ChargesCompanion toCompanion() => ChargesCompanion(
        id: _id(id),
        customerId: Value(customerId),
        amountCents: Value(amountCents),
        description: Value(description),
        txid: Value(txid),
        status: Value(status),
        createdAt: Value(createdAt),
        dueDate: Value(dueDate),
        receivedAt: Value(receivedAt),
        transactionId: Value(transactionId),
      );
}
