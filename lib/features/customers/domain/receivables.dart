import '../../../core/utils/dates.dart';
import '../../pix/domain/charge.dart';
import 'customer.dart';

final class ReceivableSummary {
  const ReceivableSummary({
    required this.totalCents,
    required this.count,
    required this.oldestDate,
  });

  final int totalCents;
  final int count;
  final DateTime oldestDate;

  int daysOpen(DateTime now) => Dates.daysBetween(oldestDate, now);
}

final class CustomerBalance {
  const CustomerBalance({required this.customer, this.receivable});

  final Customer customer;
  final ReceivableSummary? receivable;

  int get openCents => receivable?.totalCents ?? 0;
}

abstract final class Receivables {
  static Map<int?, ReceivableSummary> byCustomer(Iterable<Charge> charges) {
    final result = <int?, ReceivableSummary>{};
    for (final charge in charges.where((c) => c.isPending)) {
      final current = result[charge.customerId];
      result[charge.customerId] = current == null
          ? ReceivableSummary(
              totalCents: charge.amountCents,
              count: 1,
              oldestDate: charge.createdAt,
            )
          : ReceivableSummary(
              totalCents: current.totalCents + charge.amountCents,
              count: current.count + 1,
              oldestDate: charge.createdAt.isBefore(current.oldestDate)
                  ? charge.createdAt
                  : current.oldestDate,
            );
    }
    return result;
  }

  static int total(Iterable<Charge> charges) => charges
      .where((c) => c.isPending)
      .fold(0, (sum, charge) => sum + charge.amountCents);

  static List<CustomerBalance> balances(
    Iterable<Customer> customers,
    Iterable<Charge> charges,
  ) {
    final summaries = byCustomer(charges);
    final result = [
      for (final customer in customers)
        CustomerBalance(customer: customer, receivable: summaries[customer.id]),
    ]..sort((a, b) {
        final byOpen = b.openCents.compareTo(a.openCents);
        return byOpen != 0
            ? byOpen
            : a.customer.name.toLowerCase().compareTo(
                  b.customer.name.toLowerCase(),
                );
      });
    return result;
  }
}
