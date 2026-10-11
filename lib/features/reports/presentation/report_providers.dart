import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/dates.dart';
import '../../customers/presentation/customer_providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../data/report_exporter.dart';
import '../domain/report_data.dart';

final reportExporterProvider =
    Provider<ReportExporter>((ref) => const ReportExporter());

final reportPeriodProvider =
    NotifierProvider<ReportPeriodNotifier, ReportPeriod>(
  ReportPeriodNotifier.new,
);

class ReportPeriodNotifier extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() => thisMonth();

  static ReportPeriod thisMonth() {
    final now = DateTime.now();
    return (start: Dates.startOfMonth(now), end: Dates.startOfNextMonth(now));
  }

  static ReportPeriod lastMonth() {
    final previous = Dates.addMonths(DateTime.now(), -1);
    return (
      start: Dates.startOfMonth(previous),
      end: Dates.startOfNextMonth(previous),
    );
  }

  static ReportPeriod thisYear() {
    final now = DateTime.now();
    return (start: DateTime(now.year), end: DateTime(now.year + 1));
  }

  static ReportPeriod lastYear() {
    final now = DateTime.now();
    return (start: DateTime(now.year - 1), end: DateTime(now.year));
  }

  void select(ReportPeriod period) => state = period;

  void custom(DateTime start, DateTime lastDay) => state = (
        start: Dates.dateOnly(start),
        end: DateTime(lastDay.year, lastDay.month, lastDay.day + 1),
      );
}

final reportDataProvider =
    FutureProvider.autoDispose.family<ReportData, ReportPeriod>(
  (ref, period) async {
    final transactionRepository = ref.watch(transactionRepositoryProvider);
    final categoryRepository = ref.watch(categoryRepositoryProvider);
    final customerRepository = ref.watch(customerRepositoryProvider);
    final settingsRepository = ref.watch(settingsRepositoryProvider);
    final transactions = await transactionRepository
        .fetch(TransactionFilter(start: period.start, end: period.end));
    final categories = await categoryRepository.fetchAll();
    final customers = await customerRepository.fetchAll();
    final settings = await settingsRepository.load();
    return ReportData(
      businessName: settings.businessName,
      period: period,
      transactions: transactions,
      categories: {
        for (final c in categories)
          if (c.id case final id?) id: c,
      },
      customers: {
        for (final c in customers)
          if (c.id case final id?) id: c,
      },
      generatedAt: DateTime.now(),
    );
  },
);
