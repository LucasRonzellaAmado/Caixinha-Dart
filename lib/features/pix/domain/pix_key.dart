import '../../../core/result/result.dart';

enum PixKeyType { cpf, cnpj, phone, email, random }

extension PixKeyTypeLabel on PixKeyType {
  String get label => switch (this) {
        PixKeyType.cpf => 'CPF',
        PixKeyType.cnpj => 'CNPJ',
        PixKeyType.phone => 'Celular',
        PixKeyType.email => 'E-mail',
        PixKeyType.random => 'Chave aleatória',
      };

  String get hint => switch (this) {
        PixKeyType.cpf => '000.000.000-00',
        PixKeyType.cnpj => '00.000.000/0000-00',
        PixKeyType.phone => '(19) 99999-9999',
        PixKeyType.email => 'voce@email.com',
        PixKeyType.random => '123e4567-e89b-12d3-a456-426614174000',
      };
}

abstract final class PixKey {
  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static Result<String> normalize(PixKeyType type, String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return const Err(ValidationFailure('Informe a chave Pix.'));
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return switch (type) {
      PixKeyType.cpf => isValidCpf(digits)
          ? Ok(digits)
          : const Err(ValidationFailure('CPF inválido.')),
      PixKeyType.cnpj => isValidCnpj(digits)
          ? Ok(digits)
          : const Err(ValidationFailure('CNPJ inválido.')),
      PixKeyType.phone => _phone(digits),
      PixKeyType.email => _email.hasMatch(value) && value.length <= 77
          ? Ok(value.toLowerCase())
          : const Err(ValidationFailure('E-mail inválido.')),
      PixKeyType.random => _uuid.hasMatch(value.toLowerCase())
          ? Ok(value.toLowerCase())
          : const Err(ValidationFailure('Chave aleatória inválida.')),
    };
  }

  static Result<String> _phone(String digits) {
    if (digits.length == 10 || digits.length == 11) return Ok('+55$digits');
    if ((digits.length == 12 || digits.length == 13) &&
        digits.startsWith('55')) {
      return Ok('+$digits');
    }
    return const Err(
      ValidationFailure('Celular inválido. Use DDD + número.'),
    );
  }

  static bool isValidCpf(String digits) {
    if (digits.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(digits)) {
      return false;
    }
    final numbers = digits.split('').map(int.parse).toList();
    int check(int length) {
      var sum = 0;
      for (var i = 0; i < length; i++) {
        sum += numbers[i] * (length + 1 - i);
      }
      final rest = (sum * 10) % 11;
      return rest == 10 ? 0 : rest;
    }

    return check(9) == numbers[9] && check(10) == numbers[10];
  }

  static bool isValidCnpj(String digits) {
    if (digits.length != 14 || RegExp(r'^(\d)\1{13}$').hasMatch(digits)) {
      return false;
    }
    final numbers = digits.split('').map(int.parse).toList();
    int check(List<int> weights) {
      var sum = 0;
      for (var i = 0; i < weights.length; i++) {
        sum += numbers[i] * weights[i];
      }
      final rest = sum % 11;
      return rest < 2 ? 0 : 11 - rest;
    }

    const first = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const second = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    return check(first) == numbers[12] && check(second) == numbers[13];
  }
}
