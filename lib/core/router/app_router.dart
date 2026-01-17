import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/session_service.dart';
import '../di/service_locator.dart';
import '../../features/main/presentation/pages/main_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/accounts/presentation/pages/add_account_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/statistics/presentation/pages/statistics_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';

/// Configuración de rutas de la aplicación usando GoRouter
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final sessionService = getIt<SessionService>();
      final isLoggedIn = sessionService.isLoggedIn();
      final isLoggingIn = state.matchedLocation == '/login' ||
                           state.matchedLocation == '/register';

      // Si no está logueado y no está en páginas de auth, redirigir a login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // Si está logueado y está en páginas de auth, redirigir a dashboard
      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }

      return null; // No redirigir
    },
    routes: [
      // Rutas de autenticación
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginPage(),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => const MaterialPage(
          child: RegisterPage(),
        ),
      ),
      // Shell Route para la navegación con Bottom Navigation Bar
      // Shell Route para la navegación con Bottom Navigation Bar
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainPage(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/accounts',
            name: 'accounts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AccountsPage(),
            ),
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TransactionsPage(),
            ),
          ),
          GoRoute(
            path: '/statistics',
            name: 'statistics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StatisticsPage(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
        ],
      ),
      // Rutas fuera del Shell (pantallas completas)
      GoRoute(
        path: '/add-account',
        name: 'add-account',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: AddAccountPage(),
          fullscreenDialog: true,
        ),
      ),
      GoRoute(
        path: '/add-transaction',
        name: 'add-transaction',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'expense';
          final accountId = state.uri.queryParameters['accountId'];
          final extra = state.extra as Map<String, dynamic>?;
          
          return MaterialPage(
            child: AddTransactionPage(
              transactionType: extra?['type'] ?? type,
              preselectedAccountId: extra?['accountId'] ?? accountId,
            ),
            fullscreenDialog: true,
          );
        },
      ),
    ],
  );
}

/// Constantes de rutas
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String accounts = '/accounts';
  static const String transactions = '/transactions';
  static const String statistics = '/statistics';
  static const String settings = '/settings';
  static const String addAccount = '/add-account';
  static const String addTransaction = '/add-transaction';
}
