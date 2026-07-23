import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/common/app_widgets.dart';

/// Landing page showing all saved vehicles.
class VehicleListPage extends ConsumerStatefulWidget {
  const VehicleListPage({super.key});

  @override
  ConsumerState<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends ConsumerState<VehicleListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = _searchQuery.isEmpty
        ? ref.watch(vehicleListProvider)
        : ref.watch(vehicleSearchProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(vehicleListProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by plate, brand, model…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ).animate().fadeIn(duration: 300.ms),

          // ── Vehicle list ───────────────────────────────────────────────
          Expanded(
            child: vehiclesAsync.when(
              loading: () => const ShimmerList(),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(vehicleListProvider),
              ),
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return EmptyState(
                    icon: Icons.directions_car,
                    title: 'No vehicles yet',
                    subtitle: 'Scan a registration document to add your first vehicle.',
                    action: ElevatedButton.icon(
                      onPressed: () => context.push('${AppRoutes.vehicles}/scan'),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Scan Registration'),
                    ),
                  );
                }

                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 12, bottom: 100),
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50,
                          child: FadeInAnimation(
                            child: _VehicleCard(vehicle: vehicle),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('${AppRoutes.vehicles}/scan'),
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scan Registration'),
      ).animate().scale(delay: 500.ms, duration: 400.ms, curve: Curves.elasticOut),
    );
  }
}

class _VehicleCard extends ConsumerWidget {
  final VehicleModel vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('${AppRoutes.vehicles}/${vehicle.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ── Photo or icon ────────────────────────────────────────
              _VehicleThumbnail(imagePath: vehicle.imagePath, brand: vehicle.brand),
              const SizedBox(width: 16),

              // ── Details ───────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.displayTitle,
                      style: theme.textTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            vehicle.registration,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        if (vehicle.year != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            vehicle.year!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (vehicle.fuelType != null)
                          _tag(
                            context,
                            vehicle.fuelType!,
                            Icons.local_gas_station_outlined,
                          ),
                        if (vehicle.engineSize != null) ...[
                          const SizedBox(width: 6),
                          _tag(context, vehicle.engineSize!, Icons.settings_outlined),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Arrow ─────────────────────────────────────────────────
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 2),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _VehicleThumbnail extends StatelessWidget {
  final String? imagePath;
  final String? brand;

  const _VehicleThumbnail({this.imagePath, this.brand});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imagePath != null && File(imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(imagePath!),
          width: 64,
          height: 64,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.directions_car,
        color: theme.colorScheme.primary.withValues(alpha: 0.5),
        size: 32,
      ),
    );
  }
}
