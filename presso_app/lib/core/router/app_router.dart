import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/phone_auth_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/orders/presentation/screens/order_history_screen.dart';
import '../../features/orders/presentation/screens/service_selection_screen.dart';
import '../../features/orders/presentation/screens/garment_count_screen.dart';
import '../../features/orders/presentation/screens/pickup_slot_screen.dart';
import '../../features/orders/presentation/screens/address_screen.dart';
import '../../features/orders/presentation/screens/order_summary_screen.dart';
import '../../features/orders/presentation/screens/order_confirmed_screen.dart';
import '../../features/orders/presentation/screens/treatment_selection_screen.dart';
import '../../features/orders/presentation/screens/item_type_selection_screen.dart';
import '../../features/orders/presentation/screens/treatment_summary_screen.dart';
import '../../features/orders/presentation/screens/order_tracker_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/photo_viewer_screen.dart';
import '../../features/orders/presentation/screens/cart_screen.dart';
import '../../features/savings/presentation/screens/savings_screen.dart';
import '../../features/referral/presentation/screens/refer_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/saved_addresses_screen.dart';
import '../../features/profile/presentation/screens/add_address_screen.dart';
import '../../features/profile/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/student_verify_screen.dart';
import 'main_shell.dart';

// ── Router provider ────────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      // ── Splash ──
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (ctx, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),

      // ── Onboarding ──
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (ctx, state) => _fadeTransition(
          state,
          const OnboardingScreen(),
        ),
      ),

      // ── Auth ──
      GoRoute(
        path: '/auth/phone',
        name: 'auth-phone',
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          const PhoneAuthScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/otp',
        name: 'auth-otp',
        pageBuilder: (ctx, state) {
          final extra = state.extra;
          final phone = extra is Map<String, dynamic>
              ? (extra['phone'] as String? ?? '')
              : '';
          final verificationId = extra is Map<String, dynamic>
              ? (extra['verificationId'] as String? ?? '')
              : '';
          final resendToken = extra is Map<String, dynamic>
              ? extra['resendToken'] as int?
              : null;
          return _slideTransition(
            state,
            OtpScreen(
              phone: phone,
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        },
      ),
      GoRoute(
        path: '/auth/setup',
        name: 'auth-setup',
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          const ProfileSetupScreen(),
        ),
      ),

      // ── Main Shell with bottom nav (5 branches) ──
      StatefulShellRoute.indexedStack(
        builder: (ctx, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0 — Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                pageBuilder: (ctx, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),

          // Branch 1 — Orders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/orders',
                name: 'orders',
                pageBuilder: (ctx, state) => const NoTransitionPage(
                  child: OrderHistoryScreen(),
                ),
              ),
            ],
          ),

          // Branch 2 — Cart
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/cart',
                name: 'cart',
                pageBuilder: (ctx, state) => const NoTransitionPage(
                  child: CartScreen(),
                ),
              ),
            ],
          ),

          // Branch 3 — Savings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/savings',
                name: 'savings',
                pageBuilder: (ctx, state) => const NoTransitionPage(
                  child: SavingsScreen(),
                ),
              ),
            ],
          ),

        ],
      ),

      // ── Order flow ──
      GoRoute(
        path: '/order/services',
        name: 'order-services',
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          const ServiceSelectionScreen(),
        ),
      ),
      GoRoute(
        path: '/order/treatment/:serviceId/types',
        name: 'order-treatment-types',
        pageBuilder: (ctx, state) {
          final serviceId = state.pathParameters['serviceId'] ?? '';
          return _slideTransition(
            state,
            ItemTypeSelectionScreen(serviceId: serviceId),
          );
        },
      ),
      GoRoute(
        path: '/order/treatment/:serviceId/pick',
        name: 'order-treatment-pick',
        pageBuilder: (ctx, state) {
          final serviceId = state.pathParameters['serviceId'] ?? '';
          return _slideTransition(
            state,
            TreatmentSelectionScreen(serviceId: serviceId),
          );
        },
      ),
      GoRoute(
        path: '/order/treatment/:serviceId/summary',
        name: 'order-treatment-summary',
        pageBuilder: (ctx, state) {
          final serviceId = state.pathParameters['serviceId'] ?? '';
          return _slideTransition(
            state,
            TreatmentSummaryScreen(serviceId: serviceId),
          );
        },
      ),
      GoRoute(
        path: '/order/garments',
        name: 'order-garments',
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          const GarmentCountScreen(),
        ),
      ),
      GoRoute(
        path: '/order/slots',
        name: 'order-slots',
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          const PickupSlotScreen(),
        ),
      ),
      GoRoute(
        path: '/order/address',
        name: 'order-address',
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          const AddressScreen(),
        ),
      ),
      GoRoute(
        path: '/order/summary',
        name: 'order-summary',
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          const OrderSummaryScreen(),
        ),
      ),
      GoRoute(
        path: '/order/confirmed',
        name: 'order-confirmed',
        pageBuilder: (ctx, state) {
          final extra = state.extra;
          final orderId = extra is String
              ? extra
              : extra is Map<String, dynamic>
                  ? (extra['orderId'] as String? ?? '')
                  : '';
          return _slideTransition(
            state,
            OrderConfirmedScreen(orderId: orderId),
          );
        },
      ),

      // ── Order detail routes (parameterized) ──
      GoRoute(
        path: '/order/:id/track',
        name: 'order-track',
        pageBuilder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          return _slideTransition(
            state,
            OrderTrackerScreen(orderId: id),
          );
        },
      ),
      GoRoute(
        path: '/order/:id/detail',
        name: 'order-detail',
        pageBuilder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          return _slideTransition(
            state,
            OrderDetailScreen(orderId: id),
          );
        },
      ),
      GoRoute(
        path: '/order/:id/photos',
        name: 'order-photos',
        pageBuilder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          // photoUrls can be passed via extra as List<String>
          final extra = state.extra;
          final photoUrls = extra is List<String>
              ? extra
              : extra is Map<String, dynamic>
                  ? (extra['photoUrls'] as List<String>? ?? [])
                  : <String>[];
          return _slideTransition(
            state,
            PhotoViewerScreen(orderId: id, photoUrls: photoUrls),
          );
        },
      ),

      // ── Referral (standalone push route) ──
      GoRoute(
        path: '/referral',
        name: 'referral',
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          const ReferScreen(),
        ),
      ),

      // ── Profile (standalone push route) ──
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          const ProfileScreen(),
        ),
      ),

      // ── Profile sub-routes ──
      GoRoute(
        path: '/profile/addresses',
        name: 'profile-addresses',
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          const SavedAddressesScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/add-address',
        name: 'profile-add-address',
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          const AddAddressScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/notifications',
        name: 'profile-notifications',
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          const NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/student-verify',
        name: 'profile-student-verify',
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          const StudentVerifyScreen(),
        ),
      ),
    ],
  );
});

// ── Transition helpers ─────────────────────────────────────────────────────────

CustomTransitionPage<void> _slideTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      final tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 280),
  );
}

CustomTransitionPage<void> _fadeTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
