import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/account_screen.dart';

import '../../features/rider/presentation/screens/rider_shell_screen.dart';
import '../../features/rider/presentation/screens/rider_dashboard_screen.dart';
import '../../features/rider/presentation/screens/job_detail_screen.dart';
import '../../features/rider/presentation/screens/navigate_screen.dart';
import '../../features/rider/presentation/screens/photo_capture_screen.dart';
import '../../features/rider/presentation/screens/shoe_photo_capture_screen.dart';
import '../../features/rider/presentation/screens/garment_count_confirm_screen.dart';
import '../../features/rider/presentation/screens/otp_confirm_screen.dart';
import '../../features/rider/presentation/screens/pickup_complete_screen.dart';
import '../../features/rider/presentation/screens/delivery_screen.dart';
import '../../features/rider/presentation/screens/delivery_otp_screen.dart';
import '../../features/rider/presentation/screens/earnings_screen.dart';
import '../../features/rider/presentation/screens/history_list_screen.dart';
import '../../features/rider/presentation/screens/history_detail_screen.dart';
import '../../features/rider/presentation/screens/job_offer_screen.dart';
import '../../features/rider/presentation/screens/job_locked_screen.dart';
import '../../features/rider/presentation/screens/drop_at_facility_screen.dart';

import '../../features/facility/presentation/screens/facility_shell_screen.dart';
import '../../features/facility/presentation/screens/facility_dashboard_screen.dart';
import '../../features/facility/presentation/screens/scan_order_screen.dart';
import '../../features/facility/presentation/screens/facility_order_detail_screen.dart';
import '../../features/facility/presentation/screens/status_update_screen.dart';
import '../../features/facility/presentation/screens/dispatch_screen.dart';
import '../../features/facility/presentation/screens/drop_verify_screen.dart';

import '../../features/admin/presentation/screens/service_zones_screen.dart';
import '../../features/admin/presentation/screens/create_zone_screen.dart';

import '../../features/rider/domain/models/job_model.dart';

final _riderShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'riderShell');
final _facilityShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'facilityShell');

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // === Rider shell with persistent bottom nav ===
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RiderShellScreen(navigationShell: navigationShell),
        branches: [
          // Branch 0: Jobs
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rider/dashboard',
                builder: (context, state) => const RiderDashboardScreen(),
              ),
            ],
          ),
          // Branch 1: History
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rider/history',
                builder: (context, state) => const HistoryListScreen(),
              ),
            ],
          ),
          // Branch 2: Earnings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rider/earnings',
                builder: (context, state) => const EarningsScreen(),
              ),
            ],
          ),
          // Branch 3: Account
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rider/account',
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),

      // Rider sub-pages (outside shell — full screen, no bottom nav)
      GoRoute(
        path: '/rider/history/:assignmentId',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! AssignmentModel) {
            // Defensive: the history list always passes the model in `extra`.
            // If a deeplink lands here without it, bounce back to the list.
            return const HistoryListScreen();
          }
          return HistoryDetailScreen(job: extra);
        },
      ),
      GoRoute(
        path: '/rider/job/:assignmentId',
        builder: (context, state) => JobDetailScreen(
          assignmentId: state.pathParameters['assignmentId']!,
        ),
      ),
      GoRoute(
        path: '/rider/job/:assignmentId/navigate',
        builder: (context, state) => NavigateScreen(
          assignmentId: state.pathParameters['assignmentId']!,
        ),
      ),
      GoRoute(
        path: '/rider/job/:assignmentId/photos',
        builder: (context, state) => PhotoCaptureScreen(
          assignmentId: state.pathParameters['assignmentId']!,
        ),
      ),
      GoRoute(
        path: '/rider/job/:assignmentId/shoe-photos',
        builder: (context, state) => ShoePhotoCaptureScreen(
          assignmentId: state.pathParameters['assignmentId']!,
          shoeItems: state.extra as List<ShoeItemModel>,
        ),
      ),
      GoRoute(
        path: '/rider/job/:assignmentId/garment-confirm',
        builder: (context, state) => GarmentCountConfirmScreen(
          assignmentId: state.pathParameters['assignmentId']!,
        ),
      ),
      GoRoute(
        path: '/rider/job/:assignmentId/otp',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          return OtpConfirmScreen(
            assignmentId: state.pathParameters['assignmentId']!,
            count: extras['count'] as int? ?? 0,
            notes: extras['notes'] as String?,
            photosTaken: extras['photosTaken'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/rider/job/:assignmentId/complete',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return PickupCompleteScreen(
            assignmentId: state.pathParameters['assignmentId']!,
            count: extras['count'] as int,
            photosTaken: extras['photosTaken'] as int,
          );
        },
      ),
      GoRoute(
        path: '/rider/delivery/:assignmentId',
        builder: (context, state) => DeliveryScreen(
          assignmentId: state.pathParameters['assignmentId']!,
        ),
      ),
      GoRoute(
        path: '/rider/delivery/:assignmentId/otp',
        builder: (context, state) => DeliveryOtpScreen(
          assignmentId: state.pathParameters['assignmentId']!,
        ),
      ),

      // Wireframe screen 5 — full-screen offer takeover with 60s countdown.
      GoRoute(
        path: '/rider/offer',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! AssignmentModel) {
            return const RiderDashboardScreen();
          }
          return JobOfferScreen(offer: extra);
        },
      ),
      // Wireframe screen 6 — offer expired / lost the race.
      GoRoute(
        path: '/rider/offer/locked',
        builder: (context, state) {
          final reason = state.extra is String ? state.extra as String : 'unavailable';
          return JobLockedScreen(reason: reason);
        },
      ),
      // Wireframe screen 7 — drop bag at facility after pickup.
      GoRoute(
        path: '/rider/job/:assignmentId/drop',
        builder: (context, state) => DropAtFacilityScreen(
          assignmentId: state.pathParameters['assignmentId']!,
        ),
      ),

      // === Facility shell with persistent bottom nav ===
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            FacilityShellScreen(navigationShell: navigationShell),
        branches: [
          // Branch 0: Orders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/facility/dashboard',
                builder: (context, state) => const FacilityDashboardScreen(),
              ),
            ],
          ),
          // Branch 1: Scan
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/facility/scan',
                builder: (context, state) => const ScanOrderScreen(),
              ),
            ],
          ),
          // Branch 2: Drop-offs (rider→facility OTP handshake)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/facility/drop',
                builder: (context, state) => const DropVerifyScreen(),
              ),
            ],
          ),
          // Branch 3: Account
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/facility/account',
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),

      // Facility sub-pages (outside shell — full screen)
      GoRoute(
        path: '/facility/order/:orderId',
        builder: (context, state) => FacilityOrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: '/facility/order/:orderId/status',
        builder: (context, state) => StatusUpdateScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      // Wireframe screen 14 — facility dispatches a delivery rider.
      GoRoute(
        path: '/facility/order/:orderId/dispatch',
        builder: (context, state) => DispatchScreen(
          orderId: state.pathParameters['orderId']!,
          orderNumber: state.extra is String ? state.extra as String : '',
        ),
      ),

      // Admin routes
      GoRoute(
        path: '/admin/zones',
        builder: (context, state) => const ServiceZonesScreen(),
      ),
      GoRoute(
        path: '/admin/zones/create',
        builder: (context, state) => const CreateZoneScreen(),
      ),
      GoRoute(
        path: '/admin/zones/edit/:zoneId',
        builder: (context, state) => CreateZoneScreen(
          zoneId: state.pathParameters['zoneId']!,
        ),
      ),
    ],
  );
});
