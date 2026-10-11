import 'package:caixinha/core/fiscal/fiscal_rules.dart';
import 'package:caixinha/features/mei_limit/domain/mei_limit_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = MeiLimitCalculator(FiscalRules());
  const limit = 8100000;

  MeiLimitStatus calc(int revenue, {DateTime? now, DateTime? opening}) =>
      calculator.calculate(
        revenueCents: revenue,
        annualLimitCents: limit,
        now: now ?? DateTime(2026, 7, 1),
        openingDate: opening,
      );

  test('metade do limite em julho fica tranquilo e projeta o ano', () {
    final status = calc(4050000);
    expect(status.level, MeiLimitLevel.safe);
    expect(status.usagePercent, 50);
    expect(status.projectedCents, 8122252);
    expect(status.projectionExceeds, isTrue);
    expect(status.remainingCents, 4050000);
    expect(status.monthlyRoomCents, 4050000 ~/ 6);
  });

  test('níveis do termômetro', () {
    expect(calc(5670000).level, MeiLimitLevel.attention);
    expect(calc(7300000).level, MeiLimitLevel.danger);
    expect(calc(limit).level, MeiLimitLevel.danger);
    expect(calc(8200000).level, MeiLimitLevel.exceeded);
    expect(calc(9720000).level, MeiLimitLevel.exceeded);
    expect(calc(9800000).level, MeiLimitLevel.exceededBeyondTolerance);
  });

  test('acima do limite não sobra espaço mensal', () {
    final status = calc(9000000);
    expect(status.monthlyRoomCents, 0);
    expect(status.remainingCents, -900000);
  });

  test('MEI aberto no ano usa limite proporcional', () {
    final status = calc(
      3000000,
      now: DateTime(2026, 7, 1),
      opening: DateTime(2026, 4, 10),
    );
    expect(status.limitCents, 6075000);
    expect(status.isProportional, isTrue);
  });

  test('limite zerado não quebra o cálculo', () {
    final status = calculator.calculate(
      revenueCents: 1000,
      annualLimitCents: 0,
      now: DateTime(2026, 1, 1),
    );
    expect(status.usage, 0);
    expect(status.level, MeiLimitLevel.safe);
  });
}
