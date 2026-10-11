import '../../../core/result/result.dart';
import '../../../core/utils/money.dart';
import 'crc16.dart';

abstract final class PixPayload {
  static const _gui = 'br.gov.bcb.pix';
  static const _accents = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
    'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A',
    'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
    'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
    'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
    'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
    'Ç': 'C', 'Ñ': 'N',
  };

  static Result<String> build({
    required String key,
    required String merchantName,
    required String merchantCity,
    int? amountCents,
    String description = '',
    String txid = '***',
  }) {
    final name = sanitize(merchantName, 25);
    final city = sanitize(merchantCity, 15);
    if (key.trim().isEmpty) {
      return const Err(
        ValidationFailure('Cadastre sua chave Pix nas configurações.'),
      );
    }
    if (name.isEmpty) {
      return const Err(ValidationFailure('Informe o nome de quem recebe.'));
    }
    if (city.isEmpty) {
      return const Err(ValidationFailure('Informe a cidade de quem recebe.'));
    }
    if (amountCents != null && amountCents <= 0) {
      return const Err(ValidationFailure('O valor precisa ser maior que zero.'));
    }

    final guiField = field('00', _gui);
    final keyField = field('01', key.trim());
    final maxDescription = 99 - guiField.length - keyField.length - 4;
    var cleanDescription = sanitize(description, 72);
    if (maxDescription <= 0) {
      cleanDescription = '';
    } else if (cleanDescription.length > maxDescription) {
      cleanDescription = cleanDescription.substring(0, maxDescription).trim();
    }
    final account = guiField +
        keyField +
        (cleanDescription.isEmpty ? '' : field('02', cleanDescription));
    if (account.length > 99) {
      return const Err(ValidationFailure('A chave Pix é longa demais.'));
    }

    final buffer = StringBuffer()
      ..write(field('00', '01'))
      ..write(field('26', account))
      ..write(field('52', '0000'))
      ..write(field('53', '986'));
    if (amountCents != null) {
      buffer.write(field('54', Money.toPixAmount(amountCents)));
    }
    buffer
      ..write(field('58', 'BR'))
      ..write(field('59', name))
      ..write(field('60', city))
      ..write(field('62', field('05', sanitizeTxid(txid))))
      ..write('6304');
    final partial = buffer.toString();
    return Ok('$partial${crc16Ccitt(partial)}');
  }

  static String field(String id, String value) =>
      '$id${value.length.toString().padLeft(2, '0')}$value';

  static String sanitize(String input, int maxLength) {
    final withoutAccents =
        input.split('').map((char) => _accents[char] ?? char).join();
    final cleaned = withoutAccents
        .replaceAll(RegExp(r'[^A-Za-z0-9 .,\-/]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.length > maxLength
        ? cleaned.substring(0, maxLength).trim()
        : cleaned;
  }

  static String sanitizeTxid(String txid) {
    if (txid == '***') return txid;
    final cleaned = txid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (cleaned.isEmpty) return '***';
    return cleaned.length > 25 ? cleaned.substring(0, 25) : cleaned;
  }
}
