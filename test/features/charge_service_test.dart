import 'package:caixinha/core/result/result.dart';
import 'package:caixinha/features/pix/domain/charge.dart';
import 'package:caixinha/features/pix/domain/charge_repository.dart';
import 'package:caixinha/features/pix/domain/charge_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChargeRepository extends Mock implements ChargeRepository {}

void main() {
  final now = DateTime(2026, 10, 2, 14, 30);
  late MockChargeRepository repository;
  late ChargeService service;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(
      Charge(amountCents: 1, txid: 'X', createdAt: DateTime(2026)),
    );
  });

  setUp(() {
    repository = MockChargeRepository();
    service = ChargeService(repository, clock: () => now);
  });

  test('cria cobrança com txid alfanumérico e dados limpos', () async {
    when(() => repository.create(any())).thenAnswer((_) async => const Ok(7));

    final result = await service.create(
      amountCents: 2500,
      description: '  Encomenda  ',
      customerId: 3,
    );

    expect(result.valueOrNull, 7);
    final charge =
        verify(() => repository.create(captureAny())).captured.single as Charge;
    expect(charge.amountCents, 2500);
    expect(charge.description, 'Encomenda');
    expect(charge.customerId, 3);
    expect(charge.createdAt, now);
    expect(charge.status, ChargeStatus.pending);
    expect(charge.txid, matches(RegExp(r'^CX[0-9A-Z]{1,23}$')));
  });

  test('não cria cobrança com valor zero', () async {
    final result = await service.create(amountCents: 0);
    expect(result, isA<Err<int>>());
    verifyNever(() => repository.create(any()));
  });

  test('recebe cobrança pendente usando o relógio do serviço', () async {
    final charge = Charge(id: 1, amountCents: 900, txid: 'CX1', createdAt: now);
    when(
      () => repository.markAsReceived(
        charge,
        receivedAt: now,
        categoryId: 2,
      ),
    ).thenAnswer((_) async => const Ok(null));

    final result = await service.receive(charge, categoryId: 2);

    expect(result.isOk, isTrue);
    verify(
      () => repository.markAsReceived(charge, receivedAt: now, categoryId: 2),
    ).called(1);
  });

  test('não recebe cobrança já recebida ou cancelada', () async {
    final received = Charge(
      id: 1,
      amountCents: 900,
      txid: 'CX1',
      createdAt: now,
      status: ChargeStatus.received,
    );
    expect(await service.receive(received), isA<Err<void>>());
    expect(
      await service.cancel(received.copyWith(status: ChargeStatus.canceled)),
      isA<Err<void>>(),
    );
    verifyNever(
      () => repository.markAsReceived(
        any(),
        receivedAt: any(named: 'receivedAt'),
        categoryId: any(named: 'categoryId'),
      ),
    );
  });

  test('cobrança vencida', () {
    final charge = Charge(
      amountCents: 1,
      txid: 'A',
      createdAt: DateTime(2026, 9, 1),
      dueDate: DateTime(2026, 10, 1),
    );
    expect(charge.isOverdue(now), isTrue);
    expect(charge.isOverdue(DateTime(2026, 10, 1, 23)), isFalse);
    expect(charge.daysOpen(now), 31);
  });
}
