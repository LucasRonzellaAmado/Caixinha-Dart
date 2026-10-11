import 'package:caixinha/app.dart';
import 'package:caixinha/core/database/app_database.dart';
import 'package:caixinha/core/database/database_provider.dart';
import 'package:caixinha/features/reminders/domain/fiscal_deadline.dart';
import 'package:caixinha/features/reminders/domain/notification_service.dart';
import 'package:caixinha/features/reminders/presentation/reminder_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class FakeNotificationService implements NotificationService {
  final scheduled = <ScheduledReminder>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> cancelAll() async => scheduled.clear();

  @override
  Future<void> schedule(ScheduledReminder reminder) async =>
      scheduled.add(reminder);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding, primeiro lançamento e lembretes agendados',
      (tester) async {
    Intl.defaultLocale = 'pt_BR';
    await initializeDateFormatting('pt_BR');
    final db = AppDatabase(NativeDatabase.memory());
    final notifications = FakeNotificationService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(notifications),
        ],
        child: const CaixinhaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo ao Caixinha!'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome do negócio'),
      'Doces da Ana',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Seu nome'), 'Ana');
    await tester.ensureVisible(find.text('Começar a usar'));
    await tester.tap(find.text('Começar a usar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ana'), findsWidgets);
    expect(find.text('Saldo do negócio'), findsOneWidget);
    expect(notifications.scheduled, isNotEmpty);

    await tester.tap(find.text('Entrada').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '15000');
    await tester.enterText(
      find.widgetWithText(TextField, 'Descrição'),
      'Encomenda de brigadeiros',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Encomenda de brigadeiros'), findsWidgets);

    await tester.tap(find.text('Lançamentos'));
    await tester.pumpAndSettle();
    expect(find.text('Encomenda de brigadeiros'), findsWidgets);
    expect(find.text('+R\$ 150,00'), findsWidgets);

    await db.close();
  });
}
