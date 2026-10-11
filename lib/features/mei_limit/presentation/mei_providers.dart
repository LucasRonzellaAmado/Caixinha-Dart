import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fiscal/fiscal_providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../transactions/domain/finance_calculator.dart';
import '../../transactions/domain/transaction_enums.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../domain/mei_limit_calculator.dart';

final yearBusinessRevenueProvider = StreamProvider<int>((ref) {
  final year = ref.watch(clockProvider)().year;
  return ref
      .watch(transactionRepositoryProvider)
      .watch(
        TransactionFilter.year(
          year,
          scope: TransactionScope.business,
          type: TransactionType.income,
        ),
      )
      .map((transactions) => FinanceCalculator.summarize(transactions).incomeCents);
});

final meiStatusProvider = FutureProvider<MeiLimitStatus>((ref) async {
  final calculator = ref.watch(meiLimitCalculatorProvider);
  final clock = ref.watch(clockProvider);
  final settingsFuture = ref.watch(settingsProvider.future);
  final revenueFuture = ref.watch(yearBusinessRevenueProvider.future);
  final settings = await settingsFuture;
  final revenue = await revenueFuture;
  return calculator.calculate(
    revenueCents: revenue,
    annualLimitCents: settings.meiAnnualLimitCents,
    openingDate: settings.meiOpeningDate,
    now: clock(),
  );
});
