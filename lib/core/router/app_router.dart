import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/customers/presentation/customer_detail_page.dart';
import '../../features/customers/presentation/customer_form_page.dart';
import '../../features/customers/presentation/customers_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/mei_limit/presentation/mei_limit_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/onboarding/presentation/splash_page.dart';
import '../../features/pix/presentation/charge_detail_page.dart';
import '../../features/pix/presentation/charge_form_page.dart';
import '../../features/pix/presentation/charges_page.dart';
import '../../features/reminders/presentation/reminders_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/settings/presentation/more_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/settings/presentation/settings_providers.dart';
import '../../features/transactions/domain/transaction_enums.dart';
import '../../features/transactions/presentation/categories_page.dart';
import '../../features/transactions/presentation/transaction_form_page.dart';
import '../../features/transactions/presentation/transactions_page.dart';
import '../widgets/common.dart';
import 'app_routes.dart';
import 'home_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(settingsProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) {
      final settings = ref.read(settingsProvider);
      final location = state.matchedLocation;
      final completed = settings.value?.onboardingCompleted;
      if (completed == null) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }
      if (!completed) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }
      if (location == AppRoutes.splash || location == AppRoutes.onboarding) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    errorBuilder: (_, _) => const NotFoundPage(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (_, _) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                builder: (_, _) => const TransactionsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.charges,
                builder: (_, _) => const ChargesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (_, _) => const MorePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.newTransaction,
        builder: (_, state) {
          final params = state.uri.queryParameters;
          return TransactionFormPage(
            initialType:
                TransactionType.values.asNameMap()[params['type']] ??
                    TransactionType.income,
            initialCustomerId: int.tryParse(params['customer'] ?? ''),
          );
        },
      ),
      GoRoute(
        path: '/transactions/edit/:id',
        builder: (_, state) => _withId(
          state,
          (id) => TransactionFormPage(transactionId: id),
        ),
      ),
      GoRoute(
        path: AppRoutes.categories,
        builder: (_, _) => const CategoriesPage(),
      ),
      GoRoute(
        path: AppRoutes.newCharge,
        builder: (_, state) => ChargeFormPage(
          initialCustomerId:
              int.tryParse(state.uri.queryParameters['customer'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/charges/view/:id',
        builder: (_, state) =>
            _withId(state, (id) => ChargeDetailPage(chargeId: id)),
      ),
      GoRoute(
        path: AppRoutes.customers,
        builder: (_, _) => const CustomersPage(),
      ),
      GoRoute(
        path: AppRoutes.newCustomer,
        builder: (_, _) => const CustomerFormPage(),
      ),
      GoRoute(
        path: '/customers/view/:id',
        builder: (_, state) =>
            _withId(state, (id) => CustomerDetailPage(customerId: id)),
      ),
      GoRoute(
        path: '/customers/edit/:id',
        builder: (_, state) =>
            _withId(state, (id) => CustomerFormPage(customerId: id)),
      ),
      GoRoute(
        path: AppRoutes.meiLimit,
        builder: (_, _) => const MeiLimitPage(),
      ),
      GoRoute(
        path: AppRoutes.reminders,
        builder: (_, _) => const RemindersPage(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (_, _) => const ReportsPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsPage(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

Widget _withId(GoRouterState state, Widget Function(int id) builder) {
  final id = int.tryParse(state.pathParameters['id'] ?? '');
  return id == null ? const NotFoundPage() : builder(id);
}
