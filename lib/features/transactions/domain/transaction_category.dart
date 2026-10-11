import 'package:freezed_annotation/freezed_annotation.dart';

import 'transaction_enums.dart';

part 'transaction_category.freezed.dart';
part 'transaction_category.g.dart';

@freezed
abstract class TransactionCategory with _$TransactionCategory {
  const factory TransactionCategory({
    int? id,
    required String name,
    required TransactionType type,
    required int color,
    required String iconKey,
    @Default(false) bool archived,
  }) = _TransactionCategory;

  factory TransactionCategory.fromJson(Map<String, dynamic> json) =>
      _$TransactionCategoryFromJson(json);
}
