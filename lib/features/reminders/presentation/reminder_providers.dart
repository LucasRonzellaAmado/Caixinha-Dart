import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/fiscal/fiscal_providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../data/drift_das_payment_repository.dart';
import '../data/local_notification_service.dart';
import '../domain/das_payment_repository.dart';
import '../domain/fiscal_deadline.dart';
import '../domain/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => LocalNotificationService(),
);

final dasPaymentRepositoryProvider = Provider<DasPaymentRepository>(
  (ref) => DriftDasPaymentRepository(ref.watch(databaseProvider)),
);

final paidCompetencesProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(dasPaymentRepositoryProvider).watchPaidCompetences(),
);

final upcomingDeadlinesProvider = Provider<List<FiscalDeadline>>((ref) {
  final now = ref.watch(clockProvider)();
  return ref.watch(reminderCalculatorProvider).upcoming(now);
});

final reminderSyncProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  final calculator = ref.watch(reminderCalculatorProvider);
  final clock = ref.watch(clockProvider);
  final settingsFuture = ref.watch(settingsProvider.future);
  final paidFuture = ref.watch(paidCompetencesProvider.future);
  final settings = await settingsFuture;
  final paid = await paidFuture;

  await service.cancelAll();
  if (!settings.remindersEnabled || !settings.onboardingCompleted) return 0;

  final reminders = calculator.buildReminders(
    now: clock(),
    daysBefore: settings.reminderDaysBefore,
    paidCompetences: paid,
  );
  for (final reminder in reminders) {
    await service.schedule(reminder);
  }
  return reminders.length;
});
