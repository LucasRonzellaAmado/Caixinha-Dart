abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const dashboard = '/dashboard';
  static const transactions = '/transactions';
  static const newTransaction = '/transactions/new';
  static const charges = '/charges';
  static const newCharge = '/charges/new';
  static const more = '/more';
  static const customers = '/customers';
  static const newCustomer = '/customers/new';
  static const categories = '/categories';
  static const meiLimit = '/mei-limit';
  static const reminders = '/reminders';
  static const reports = '/reports';
  static const settings = '/settings';

  static String newTransactionOf({String? type, int? customerId}) {
    final query = [
      if (type != null) 'type=$type',
      if (customerId != null) 'customer=$customerId',
    ];
    return query.isEmpty ? newTransaction : '$newTransaction?${query.join('&')}';
  }

  static String editTransaction(int id) => '/transactions/edit/$id';

  static String charge(int id) => '/charges/view/$id';

  static String newChargeFor(int customerId) =>
      '$newCharge?customer=$customerId';

  static String customer(int id) => '/customers/view/$id';

  static String editCustomer(int id) => '/customers/edit/$id';
}
