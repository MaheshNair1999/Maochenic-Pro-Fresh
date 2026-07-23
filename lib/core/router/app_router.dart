import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/pages/vehicle/vehicle_list_page.dart';
import '../../presentation/pages/vehicle/vehicle_detail_page.dart';
import '../../presentation/pages/vehicle/scan_registration_page.dart';
import '../../presentation/pages/parts/parts_scanner_page.dart';
import '../../presentation/pages/inventory/inventory_page.dart';
import '../../presentation/pages/inventory/inventory_item_detail_page.dart';
import '../../presentation/pages/jobsheet/job_list_page.dart';
import '../../presentation/pages/jobsheet/job_detail_page.dart';
import '../../presentation/pages/history/history_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/widgets/common/main_scaffold.dart';

/// Named route constants — avoids typos across the codebase.
class AppRoutes {
  static const String home = '/';
  static const String vehicles = '/vehicles';
  static const String vehicleDetail = '/vehicles/:id';
  static const String scanRegistration = '/vehicles/scan';
  static const String parts = '/parts';
  static const String inventory = '/inventory';
  static const String inventoryDetail = '/inventory/:id';
  static const String jobs = '/jobs';
  static const String jobDetail = '/jobs/:id';
  static const String history = '/history';
  static const String settings = '/settings';
}

/// Provides the configured GoRouter instance via Riverpod.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.vehicles,
    debugLogDiagnostics: false,
    routes: [
      // ── Shell route wraps the main scaffold with bottom nav ───────────────
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.vehicles,
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const VehicleListPage(),
            ),
            routes: [
              GoRoute(
                path: 'scan',
                pageBuilder: (context, state) => _slideTransition(
                  state,
                  const ScanRegistrationPage(),
                ),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _slideTransition(
                  state,
                  VehicleDetailPage(
                    vehicleId: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.parts,
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const PartsScannerPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.inventory,
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const InventoryPage(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _slideTransition(
                  state,
                  InventoryItemDetailPage(
                    itemId: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.jobs,
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const JobListPage(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _slideTransition(
                  state,
                  JobDetailPage(
                    jobId: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.history,
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const HistoryPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const SettingsPage(),
            ),
          ),
        ],
      ),
    ],
  );
});

// ── Transition helpers ────────────────────────────────────────────────────────

CustomTransitionPage<void> _fadeTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}

CustomTransitionPage<void> _slideTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeInOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
