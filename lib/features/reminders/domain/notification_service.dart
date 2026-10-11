import 'fiscal_deadline.dart';

abstract interface class NotificationService {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<void> cancelAll();

  Future<void> schedule(ScheduledReminder reminder);
}
