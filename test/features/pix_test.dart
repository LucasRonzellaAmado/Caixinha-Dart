import 'package:caixinha/core/result/result.dart';
import 'package:caixinha/features/pix/domain/crc16.dart';
import 'package:caixinha/features/pix/domain/pix_key.dart';
import 'package:caixinha/features/pix/domain/pix_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CRC16', () {
    test('valor de verificação do CRC-16/CCITT-FALSE', () {
      expect(crc16Ccitt('123456789'), '29B1');
    });
  });

  group('PixPayload', () {
    test('reproduz o exemplo do manual do Banco Central', () {
      final result = PixPayload.build(
        key: '123e4567-e12b-12d1-a456-426655440000',
        merchantName: 'Fulano de Tal',
        merchantCity: 'BRASILIA',
      );
      expect(
        result.valueOrNull,
        '00020126580014br.gov.bcb.pix0136123e4567-e12b-12d1-a456-426655440000'
        '5204000053039865802BR5913Fulano de Tal6008BRASILIA62070503***63041D3D',
      );
    });

    test('inclui valor, descrição e txid', () {
      final result = PixPayload.build(
        key: '+5519999998888',
        merchantName: 'Lucas Ronzella',
        merchantCity: 'Americana',
        amountCents: 1550,
        description: 'Bolo',
        txid: 'CX123',
      );
      expect(
        result.valueOrNull,
        '00020126440014br.gov.bcb.pix0114+55199999988880204Bolo52040000'
        '5303986540515.505802BR5914Lucas Ronzella6009Americana62090505CX123'
        '630471F9',
      );
    });

    test('remove acentos e corta nome e cidade', () {
      expect(PixPayload.sanitize('São José dos Campos', 15), 'Sao Jose dos Ca');
      expect(PixPayload.sanitize('Doçaria Coração!', 25), 'Docaria Coracao');
      expect(PixPayload.sanitizeTxid('ab-12 cd'), 'ab12cd');
      expect(PixPayload.sanitizeTxid('---'), '***');
    });

    test('rejeita dados incompletos', () {
      expect(
        PixPayload.build(key: '', merchantName: 'A', merchantCity: 'B'),
        isA<Err<String>>(),
      );
      expect(
        PixPayload.build(
          key: 'a@b.com',
          merchantName: 'A',
          merchantCity: 'B',
          amountCents: 0,
        ),
        isA<Err<String>>(),
      );
    });

    test('payload termina sempre com CRC válido', () {
      final payload = PixPayload.build(
        key: 'loja@exemplo.com',
        merchantName: 'Loja',
        merchantCity: 'Campinas',
        amountCents: 99990,
      ).valueOrNull!;
      final body = payload.substring(0, payload.length - 4);
      expect(payload.substring(payload.length - 4), crc16Ccitt(body));
    });
  });

  group('PixKey', () {
    test('normaliza chaves válidas', () {
      expect(PixKey.normalize(PixKeyType.cpf, '529.982.247-25').valueOrNull,
          '52998224725');
      expect(
        PixKey.normalize(PixKeyType.cnpj, '11.222.333/0001-81').valueOrNull,
        '11222333000181',
      );
      expect(PixKey.normalize(PixKeyType.phone, '(19) 99999-8888').valueOrNull,
          '+5519999998888');
      expect(PixKey.normalize(PixKeyType.email, ' Ana@Email.com ').valueOrNull,
          'ana@email.com');
    });

    test('rejeita chaves inválidas', () {
      expect(PixKey.normalize(PixKeyType.cpf, '111.111.111-11').isOk, isFalse);
      expect(PixKey.normalize(PixKeyType.cpf, '529.982.247-26').isOk, isFalse);
      expect(PixKey.normalize(PixKeyType.phone, '1234').isOk, isFalse);
      expect(PixKey.normalize(PixKeyType.email, 'sem-arroba').isOk, isFalse);
      expect(PixKey.normalize(PixKeyType.random, 'abc').isOk, isFalse);
    });
  });
}
