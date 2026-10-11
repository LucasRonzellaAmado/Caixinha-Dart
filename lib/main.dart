import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'features/reminders/data/local_notification_service.dart';
import 'features/reminders/presentation/reminder_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');

  final notifications = LocalNotificationService();
  try {
    await notifications.initialize();
  } on Object catch (error, stackTrace) {
    debugPrint('Falha ao iniciar notificações: $error\n$stackTrace');
  }

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const CaixinhaApp(),
    ),
  );
}
