import 'package:caixinha/core/fiscal/fiscal_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rules = FiscalRules();

  test('calcula a Páscoa corretamente', () {
    expect(BankHolidays.easterSunday(2026), DateTime(2026, 4, 5));
    expect(BankHolidays.easterSunday(2027), DateTime(2027, 3, 28));
    expect(BankHolidays.easterSunday(2025), DateTime(2025, 4, 20));
  });

  test('reconhece feriados fixos e móveis', () {
    expect(BankHolidays.isHoliday(DateTime(2026, 11, 20)), isTrue);
    expect(BankHolidays.isHoliday(DateTime(2026, 4, 3)), isTrue);
    expect(BankHolidays.isHoliday(DateTime(2026, 2, 17)), isTrue);
    expect(BankHolidays.isHoliday(DateTime(2026, 6, 4)), isTrue);
    expect(BankHolidays.isHoliday(DateTime(2026, 10, 2)), isFalse);
  });

  group('vencimento do DAS', () {
    test('vence dia 20 do mês seguinte', () {
      expect(rules.dasDueDate(DateTime(2026, 9)), DateTime(2026, 10, 20));
    });

    test('adia para o próximo dia útil no fim de semana', () {
      expect(rules.dasDueDate(DateTime(2026, 5)), DateTime(2026, 6, 22));
      expect(rules.dasDueDate(DateTime(2026, 11)), DateTime(2026, 12, 21));
    });

    test('adia quando dia 20 é feriado', () {
      expect(rules.dasDueDate(DateTime(2026, 10)), DateTime(2026, 11, 23));
    });

    test('virada de ano', () {
      expect(rules.dasDueDate(DateTime(2026, 12)), DateTime(2027, 1, 20));
    });
  });

  test('limite proporcional para quem abriu o MEI no ano', () {
    expect(
      rules.effectiveAnnualLimit(
        annualLimitCents: 8100000,
        year: 2026,
        openingDate: DateTime(2026, 4, 10),
      ),
      6075000,
    );
    expect(
      rules.effectiveAnnualLimit(
        annualLimitCents: 8100000,
        year: 2026,
        openingDate: DateTime(2024, 4, 10),
      ),
      8100000,
    );
  });
}
