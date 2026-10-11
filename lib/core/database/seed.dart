import 'package:drift/drift.dart';

import '../../features/transactions/domain/transaction_enums.dart';
import 'app_database.dart';

List<CategoriesCompanion> defaultCategories() => [
      _category('Vendas', TransactionType.income, 0xFF2E7D32, 'sell'),
      _category('Serviços', TransactionType.income, 0xFF00897B, 'handyman'),
      _category('Outras entradas', TransactionType.income, 0xFF558B2F, 'add'),
      _category('Mercadorias', TransactionType.expense, 0xFF6D4C41, 'inventory'),
      _category('Impostos (DAS)', TransactionType.expense, 0xFF5E35B1, 'tax'),
      _category('Aluguel', TransactionType.expense, 0xFF3949AB, 'home'),
      _category('Contas', TransactionType.expense, 0xFF0277BD, 'bill'),
      _category('Transporte', TransactionType.expense, 0xFFEF6C00, 'car'),
      _category('Alimentação', TransactionType.expense, 0xFFD84315, 'food'),
      _category('Marketing', TransactionType.expense, 0xFFAD1457, 'campaign'),
      _category('Equipamentos', TransactionType.expense, 0xFF455A64, 'tools'),
      _category('Outras saídas', TransactionType.expense, 0xFF757575, 'other'),
    ];

CategoriesCompanion _category(
  String name,
  TransactionType type,
  int color,
  String iconKey,
) =>
    CategoriesCompanion.insert(
      name: name,
      type: type,
      color: color,
      iconKey: iconKey,
      archived: const Value(false),
    );
