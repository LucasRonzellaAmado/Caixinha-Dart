import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/fiscal/fiscal_providers.dart';
import '../../../core/result/result.dart';
import '../../settings/domain/app_settings.dart';
import '../data/drift_charge_repository.dart';
import '../domain/charge.dart';
import '../domain/charge_repository.dart';
import '../domain/charge_service.dart';
import '../domain/pix_payload.dart';

final chargeRepositoryProvider = Provider<ChargeRepository>(
  (ref) => DriftChargeRepository(ref.watch(databaseProvider)),
);

final chargeServiceProvider = Provider<ChargeService>(
  (ref) => ChargeService(
    ref.watch(chargeRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

final pendingChargesProvider = StreamProvider<List<Charge>>(
  (ref) => ref
      .watch(chargeRepositoryProvider)
      .watchAll(status: ChargeStatus.pending),
);

final closedChargesProvider = StreamProvider<List<Charge>>((ref) {
  return ref.watch(chargeRepositoryProvider).watchAll().map(
        (charges) => charges.where((charge) => !charge.isPending).toList(),
      );
});

final chargeByIdProvider = StreamProvider.autoDispose.family<Charge?, int>(
  (ref, id) => ref.watch(chargeRepositoryProvider).watchById(id),
);

final customerChargesProvider =
    StreamProvider.autoDispose.family<List<Charge>, int>(
  (ref, customerId) =>
      ref.watch(chargeRepositoryProvider).watchAll(customerId: customerId),
);

Result<String> buildChargePayload(AppSettings settings, Charge charge) =>
    PixPayload.build(
      key: settings.pixKey,
      merchantName: settings.pixReceiverName,
      merchantCity: settings.pixCity,
      amountCents: charge.amountCents,
      description: charge.description,
      txid: charge.txid,
    );
