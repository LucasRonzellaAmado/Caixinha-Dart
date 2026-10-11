import 'package:caixinha/core/fiscal/fiscal_rules.dart';
import 'package:caixinha/core/theme/app_theme.dart';
import 'package:caixinha/core/widgets/amount_field.dart';
import 'package:caixinha/features/mei_limit/domain/mei_limit_calculator.dart';
import 'package:caixinha/features/mei_limit/presentation/widgets/mei_thermometer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  const calculator = MeiLimitCalculator(FiscalRules());

  testWidgets('termômetro mostra percentual, valores e mensagem', (tester) async {
    final status = calculator.calculate(
      revenueCents: 7300000,
      annualLimitCents: 8100000,
      now: DateTime(2026, 10, 2),
    );
    await tester.pumpWidget(wrap(MeiThermometer(status: status)));

    expect(find.text('90%'), findsOneWidget);
    expect(find.text('R\$ 73.000,00 de R\$ 81.000,00'), findsOneWidget);
    expect(find.textContaining('muito perto do limite'), findsOneWidget);

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, closeTo(0.901, 0.001));
  });

  testWidgets('termômetro acima do limite trava a barra cheia', (tester) async {
    final status = calculator.calculate(
      revenueCents: 9900000,
      annualLimitCents: 8100000,
      now: DateTime(2026, 10, 2),
    );
    await tester.pumpWidget(wrap(MeiThermometer(status: status)));

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 1);
    expect(find.textContaining('mais de 20%'), findsOneWidget);
  });

  testWidgets('termômetro tem descrição para leitor de tela', (tester) async {
    final handle = tester.ensureSemantics();
    final status = calculator.calculate(
      revenueCents: 4050000,
      annualLimitCents: 8100000,
      now: DateTime(2026, 7, 1),
    );
    await tester.pumpWidget(wrap(MeiThermometer(status: status)));
    expect(
      find.bySemanticsLabel(RegExp('Limite do MEI em 2026')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('campo de valor trata dígitos como centavos', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(wrap(AmountField(controller: controller)));

    await tester.enterText(find.byType(TextField), '123456');
    expect(controller.text, '1.234,56');
    expect(AmountField.centsOf(controller), 123456);

    await tester.enterText(find.byType(TextField), '7');
    expect(controller.text, '0,07');
    controller.dispose();
  });
}
