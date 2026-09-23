import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_master/core/constants.dart';
import 'package:pos_master/presentation/providers/auth_provider.dart';
import 'package:pos_master/presentation/providers/business_settings_provider.dart';
import 'package:pos_master/presentation/screens/admin_screen.dart';
import 'package:pos_master/presentation/screens/checkout_screen.dart';
import 'package:pos_master/presentation/screens/login_screen.dart';
import 'package:pos_master/presentation/screens/orders_screen.dart';
import 'package:pos_master/presentation/screens/pos_screen.dart';
import 'package:pos_master/presentation/screens/product_management_screen.dart';
import 'package:pos_master/presentation/screens/setup_screen.dart';

/// GoRouter configuration with authentication
class AppRouter {
  static GoRouter router(WidgetRef ref) => GoRouter(
        initialLocation: ref.read(businessSettingsProvider).isConfigured
            ? AppRoutes.login
            : AppRoutes.setup,
        redirect: (context, state) {
          final settings = ref.read(businessSettingsProvider);
          final isLoggedIn = ref.read(isLoggedInProvider);
          final currentUser = ref.read(currentUserProvider);
          final isLoggingIn = state.matchedLocation == AppRoutes.login;

          if (!settings.isConfigured) {
            return state.matchedLocation == AppRoutes.setup
                ? null
                : AppRoutes.setup;
          }
          if (settings.isConfigured &&
              state.matchedLocation == AppRoutes.setup) {
            return AppRoutes.login;
          }

          if (!isLoggedIn && !isLoggingIn) {
            return AppRoutes.login;
          }

          if (isLoggedIn && isLoggingIn) {
            return AppRoutes.pos;
          }

          // Admin-only guards
          final isAdminPath = state.matchedLocation.startsWith(AppRoutes.admin);
          if (isAdminPath) {
            final isAdmin = currentUser?.role == UserRole.admin;
            if (!isAdmin) return AppRoutes.pos;
          }

          if (state.matchedLocation == AppRoutes.orders &&
              currentUser?.role == UserRole.customer) {
            return AppRoutes.pos;
          }

          return null;
        },
        routes: [
          GoRoute(
            path: AppRoutes.setup,
            name: 'setup',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SetupScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.login,
            name: 'login',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const LoginScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.pos,
            name: 'pos',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const PosScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.checkout,
            name: 'checkout',
            pageBuilder: (context, state) => MaterialPage(
              child: const CheckoutScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.orders,
            name: 'orders',
            pageBuilder: (context, state) => MaterialPage(
              child: const OrdersScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.admin,
            name: 'admin',
            pageBuilder: (context, state) => MaterialPage(
              child: const AdminScreen(),
            ),
            routes: [
              GoRoute(
                path: 'products',
                name: 'admin-products',
                pageBuilder: (context, state) => MaterialPage(
                  child: const ProductManagementScreen(),
                ),
              ),
              GoRoute(
                path: 'settings',
                name: 'admin-settings',
                pageBuilder: (context, state) => const MaterialPage(
                  child: SetupScreen(destinationAfterSave: '/admin'),
                ),
              ),
            ],
          ),
        ],
      );
}

/// Route path constants
class AppRoutes {
  static const String setup = '/setup';
  static const String login = '/login';
  static const String pos = '/pos';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String admin = '/admin';
}
