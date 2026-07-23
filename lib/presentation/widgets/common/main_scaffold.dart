import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/router/app_router.dart';

/// Main application shell with a bottom navigation bar.
/// Wraps all primary-level pages.
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  // Maps route prefixes to tab indices
  static const List<String> _routes = [
    AppRoutes.vehicles,
    AppRoutes.parts,
    AppRoutes.inventory,
    AppRoutes.jobs,
    AppRoutes.history,
    AppRoutes.settings,
  ];

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.directions_car_outlined),
      selectedIcon: Icon(Icons.directions_car),
      label: 'Vehicles',
    ),
    NavigationDestination(
      icon: Icon(Icons.qr_code_scanner_outlined),
      selectedIcon: Icon(Icons.qr_code_scanner),
      label: 'Scanner',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Inventory',
    ),
    NavigationDestination(
      icon: Icon(Icons.assignment_outlined),
      selectedIcon: Icon(Icons.assignment),
      label: 'Jobs',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: 'History',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine current tab from route location
    final location = GoRouterState.of(context).uri.path;
    int currentIndex = 0;
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) {
        currentIndex = i;
        break;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          context.go(_routes[index]);
        },
        destinations: _destinations,
        animationDuration: const Duration(milliseconds: 300),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        height: 72,
      ).animate().slideY(
            begin: 1,
            end: 0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          ),
    );
  }
}
