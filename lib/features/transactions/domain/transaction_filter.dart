import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/dates.dart';
import 'financial_transaction.dart';
import 'transaction_enums.dart';

part 'transaction_filter.freezed.dart';

@freezed
abstract class TransactionFilter with _$TransactionFilter {
  const TransactionFilter._();

  const factory TransactionFilter({
    DateTime? start,
    DateTime? end,
    TransactionType? type,
    TransactionScope? scope,
    int? categoryId,
    int? customerId,
    @Default('') String query,
  }) = _TransactionFilter;

  factory TransactionFilter.month(DateTime month, {TransactionScope? scope}) =>
      TransactionFilter(
        start: Dates.startOfMonth(month),
        end: Dates.startOfNextMonth(month),
        scope: scope,
      );

  factory TransactionFilter.year(
    int year, {
    TransactionScope? scope,
    TransactionType? type,
  }) =>
      TransactionFilter(
        start: DateTime(year),
        end: DateTime(year + 1),
        scope: scope,
        type: type,
      );

  bool get hasExtraFilters =>
      type != null || scope != null || categoryId != null || query.isNotEmpty;

  bool matches(FinancialTransaction transaction) {
    final from = start;
    final until = end;
    final search = query.trim().toLowerCase();
    return (from == null || !transaction.date.isBefore(from)) &&
        (until == null || transaction.date.isBefore(until)) &&
        (type == null || transaction.type == type) &&
        (scope == null || transaction.scope == scope) &&
        (categoryId == null || transaction.categoryId == categoryId) &&
        (customerId == null || transaction.customerId == customerId) &&
        (search.isEmpty ||
            transaction.description.toLowerCase().contains(search) ||
            (transaction.notes ?? '').toLowerCase().contains(search));
  }
}
