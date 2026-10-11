import 'package:caixinha/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money.format', () {
    test('formata centavos em reais com separador de milhar', () {
      expect(Money.format(123456), 'R\$ 1.234,56');
      expect(Money.format(5), 'R\$ 0,05');
      expect(Money.format(0), 'R\$ 0,00');
      expect(Money.format(100000000), 'R\$ 1.000.000,00');
    });

    test('formata valores negativos e sem símbolo', () {
      expect(Money.format(-1990), '-R\$ 19,90');
      expect(Money.format(1990, symbol: false), '19,90');
      expect(Money.formatSigned(1990), '+R\$ 19,90');
    });
  });

  group('Money.parse', () {
    test('lê valores digitados no padrão brasileiro', () {
      expect(Money.parse('1.234,56'), 123456);
      expect(Money.parse('R\$ 10'), 1000);
      expect(Money.parse('10,5'), 1050);
      expect(Money.parse('-3,20'), -320);
    });

    test('rejeita entradas inválidas', () {
      expect(Money.parse(''), isNull);
      expect(Money.parse('abc'), isNull);
      expect(Money.parse('1,234'), isNull);
      expect(Money.parse('1,2,3'), isNull);
    });
  });

  test('converte para o formato do Pix e do CSV', () {
    expect(Money.toPixAmount(1550), '15.50');
    expect(Money.toPixAmount(7), '0.07');
    expect(Money.toDecimalString(-123456), '-1234,56');
    expect(Money.fromDigits('12.345,67'), 1234567);
  });
}
