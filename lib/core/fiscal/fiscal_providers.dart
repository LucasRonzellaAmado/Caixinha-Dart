import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/mei_limit/domain/mei_limit_calculator.dart';
import '../../features/reminders/domain/reminder_calculator.dart';
import 'fiscal_rules.dart';

final fiscalRulesProvider = Provider<FiscalRules>((ref) => const FiscalRules());

final meiLimitCalculatorProvider = Provider<MeiLimitCalculator>(
  (ref) => MeiLimitCalculator(ref.watch(fiscalRulesProvider)),
);

final reminderCalculatorProvider = Provider<ReminderCalculator>(
  (ref) => ReminderCalculator(ref.watch(fiscalRulesProvider)),
);

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
