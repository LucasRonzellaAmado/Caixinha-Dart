import 'package:drift/drift.dart';

import '../../features/pix/domain/charge.dart';
import '../../features/transactions/domain/transaction_enums.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  TextColumn get type => textEnum<TransactionType>()();
  IntColumn get color => integer()();
  TextColumn get iconKey => text()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

@DataClassName('CustomerRow')
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get phone => text().nullable()();
  TextColumn get document => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('TransactionRow')
@TableIndex(name: 'transactions_date_idx', columns: {#date})
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => textEnum<TransactionType>()();
  TextColumn get scope => textEnum<TransactionScope>()();
  IntColumn get amountCents => integer()();
  DateTimeColumn get date => dateTime()();
  IntColumn get categoryId => integer()
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();
  TextColumn get paymentMethod => textEnum<PaymentMethod>()();
  IntColumn get customerId => integer()
      .nullable()
      .references(Customers, #id, onDelete: KeyAction.setNull)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get notes => text().nullable()();
  IntColumn get chargeId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ChargeRow')
class Charges extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer()
      .nullable()
      .references(Customers, #id, onDelete: KeyAction.setNull)();
  IntColumn get amountCents => integer()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get txid => text()();
  TextColumn get status => textEnum<ChargeStatus>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get receivedAt => dateTime().nullable()();
  IntColumn get transactionId => integer().nullable()();
}

@DataClassName('DasPaymentRow')
class DasPayments extends Table {
  TextColumn get competence => text()();
  DateTimeColumn get paidAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {competence};
}

@DataClassName('SettingRow')
class SettingsEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
