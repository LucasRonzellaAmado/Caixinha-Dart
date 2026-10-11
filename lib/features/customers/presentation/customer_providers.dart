import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../pix/presentation/charge_providers.dart';
import '../data/drift_customer_repository.dart';
import '../domain/customer.dart';
import '../domain/customer_repository.dart';
import '../domain/receivables.dart';

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => DriftCustomerRepository(ref.watch(databaseProvider)),
);

final customersProvider = StreamProvider<List<Customer>>(
  (ref) => ref.watch(customerRepositoryProvider).watchAll(),
);

final customersByIdProvider = Provider<Map<int, Customer>>((ref) {
  final customers = ref.watch(customersProvider).value ?? const <Customer>[];
  return {
    for (final customer in customers)
      if (customer.id case final id?) id: customer,
  };
});

final customerByIdProvider = StreamProvider.autoDispose.family<Customer?, int>(
  (ref, id) => ref.watch(customerRepositoryProvider).watchById(id),
);

final customerBalancesProvider =
    FutureProvider<List<CustomerBalance>>((ref) async {
  final customersFuture = ref.watch(customersProvider.future);
  final pendingFuture = ref.watch(pendingChargesProvider.future);
  final customers = await customersFuture;
  final pending = await pendingFuture;
  return Receivables.balances(customers, pending);
});

final totalReceivableProvider = FutureProvider<int>((ref) async {
  final pending = await ref.watch(pendingChargesProvider.future);
  return Receivables.total(pending);
});
