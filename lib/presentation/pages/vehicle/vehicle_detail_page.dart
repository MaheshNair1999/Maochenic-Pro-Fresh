import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/job_model.dart';
import '../../../data/models/vehicle_context.dart';
import '../../../data/models/vehicle_model.dart';
import '../../providers/job_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/common/app_widgets.dart';

/// Shows full vehicle information and its associated jobs.
class VehicleDetailPage extends ConsumerWidget {
  final int vehicleId;
  const VehicleDetailPage({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(vehicleByIdProvider(vehicleId));

    return vehicleAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Vehicle')),
        body: ErrorState(message: e.toString()),
      ),
      data: (vehicle) {
        if (vehicle == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Vehicle not found.')),
          );
        }
        return _VehicleDetailView(vehicle: vehicle);
      },
    );
  }
}

class _VehicleDetailView extends ConsumerWidget {
  final VehicleModel vehicle;
  const _VehicleDetailView({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final jobsAsync = ref.watch(vehicleJobsProvider(vehicle.id!));
    final activeContext = ref.watch(activeVehicleContextProvider);

    if (activeContext?.vehicleId != vehicle.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeVehicleContextProvider.notifier).state =
            VehicleContext.fromVehicle(vehicle);
      });
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Collapsing header ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: vehicle.imagePath != null ? 240 : 120,
            pinned: true,
            title: Text(vehicle.displayTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(context, ref, vehicle),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, ref, vehicle),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: vehicle.imagePath != null &&
                      File(vehicle.imagePath!).existsSync()
                  ? Image.file(
                      File(vehicle.imagePath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.directions_car,
                          size: 64,
                          color: Colors.white30,
                        ),
                      ),
                    ),
            ),
          ),

          // ── Registration plate badge ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      vehicle.registration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (vehicle.year != null)
                    Text(vehicle.year!, style: theme.textTheme.headlineSmall),
                ],
              ),
            ),
          ),

          // ── Info grid ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vehicle Info',
                          style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      _InfoGrid(vehicle: vehicle),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),
          ),

          // ── Jobs header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Job Sheets', style: theme.textTheme.headlineMedium),
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.parts),
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('Scan Part'),
                  ),
                ],
              ),
            ),
          ),

          // ── Jobs list ─────────────────────────────────────────────────
          jobsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: ShimmerCard(height: 80),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: ErrorState(message: e.toString()),
            ),
            data: (jobs) {
              if (jobs.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No jobs yet',
                    subtitle: 'Create a job sheet to track parts and work.',
                    action: ElevatedButton.icon(
                      onPressed: () => _createJob(context, ref, vehicle),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Job'),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _JobCard(job: jobs[index]),
                  childCount: jobs.length,
                ),
              );
            },
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createJob(context, ref, vehicle),
        icon: const Icon(Icons.add),
        label: const Text('New Job'),
      ),
    );
  }

  Future<void> _createJob(
    BuildContext context,
    WidgetRef ref,
    VehicleModel vehicle,
  ) async {
    final now = DateTime.now();
    final job = JobModel(
      vehicleId: vehicle.id!,
      date: now,
      createdAt: now,
      updatedAt: now,
    );
    final id = await ref.read(vehicleJobsProvider(vehicle.id!).notifier).addJob(job);
    if (context.mounted) {
      context.push('${AppRoutes.jobs}/$id');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    VehicleModel vehicle,
  ) async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: 'Delete Vehicle',
      content:
          'Delete ${vehicle.displayTitle}? All associated jobs will also be deleted.',
    );
    if (confirmed && context.mounted) {
      await ref.read(vehicleListProvider.notifier).deleteVehicle(vehicle.id!);
      if (!context.mounted) return;
      context.pop();
    }
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    VehicleModel vehicle,
  ) {
    // Navigate to an edit screen (reuses scan page form without camera)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditVehicleSheet(vehicle: vehicle, ref: ref),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final VehicleModel vehicle;
  const _InfoGrid({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final fields = <(String, String?, IconData)>[
      ('VIN', vehicle.vin, Icons.pin_outlined),
      ('Brand', vehicle.brand, Icons.business_outlined),
      ('Model', vehicle.model, Icons.directions_car_outlined),
      ('Fuel', vehicle.fuelType, Icons.local_gas_station_outlined),
      ('Engine', vehicle.engineSize, Icons.settings_outlined),
      ('Year', vehicle.year, Icons.calendar_today_outlined),
      ('Owner', vehicle.owner, Icons.person_outlined),
      ('Colour', vehicle.color, Icons.color_lens_outlined),
    ];

    final visible = fields.where((f) => f.$2 != null && f.$2!.isNotEmpty).toList();
    if (visible.isEmpty) return const Text('No additional details.');

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: visible.map((f) => _InfoChip(label: f.$1, value: f.$2!, icon: f.$3)).toList(),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  const _JobCard({required this.job});

  Color _statusColor(JobStatus s) => switch (s) {
        JobStatus.open => const Color(0xFF1B4F72),
        JobStatus.inProgress => const Color(0xFFF39C12),
        JobStatus.completed => const Color(0xFF1E8449),
        JobStatus.cancelled => const Color(0xFFC0392B),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd MMM yyyy').format(job.date);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('${AppRoutes.jobs}/${job.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: _statusColor(job.status),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          job.customer ?? 'Job #${job.id}',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const Spacer(),
                        StatusChip(
                          label: job.status.displayName,
                          color: _statusColor(job.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(dateStr, style: theme.textTheme.bodySmall),
                        const SizedBox(width: 12),
                        Icon(Icons.build_outlined,
                            size: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          '${job.totalPartsCount} part(s)',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Inline edit sheet ──────────────────────────────────────────────────────────

class _EditVehicleSheet extends StatefulWidget {
  final VehicleModel vehicle;
  final WidgetRef ref;

  const _EditVehicleSheet({required this.vehicle, required this.ref});

  @override
  State<_EditVehicleSheet> createState() => _EditVehicleSheetState();
}

class _EditVehicleSheetState extends State<_EditVehicleSheet> {
  late final TextEditingController _regCtrl;
  late final TextEditingController _vinCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _ownerCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _regCtrl = TextEditingController(text: v.registration);
    _vinCtrl = TextEditingController(text: v.vin ?? '');
    _brandCtrl = TextEditingController(text: v.brand ?? '');
    _modelCtrl = TextEditingController(text: v.model ?? '');
    _yearCtrl = TextEditingController(text: v.year ?? '');
    _ownerCtrl = TextEditingController(text: v.owner ?? '');
  }

  @override
  void dispose() {
    _regCtrl.dispose(); _vinCtrl.dispose(); _brandCtrl.dispose();
    _modelCtrl.dispose(); _yearCtrl.dispose(); _ownerCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.vehicle.copyWith(
      registration: _regCtrl.text.trim(),
      vin: _vinCtrl.text.trim(),
      brand: _brandCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      year: _yearCtrl.text.trim(),
      owner: _ownerCtrl.text.trim(),
    );
    await widget.ref.read(vehicleListProvider.notifier).updateVehicle(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Edit Vehicle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          LabelledTextField(label: 'Registration', controller: _regCtrl),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: LabelledTextField(label: 'Brand', controller: _brandCtrl)),
              const SizedBox(width: 12),
              Expanded(child: LabelledTextField(label: 'Model', controller: _modelCtrl)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: LabelledTextField(label: 'Year', controller: _yearCtrl)),
              const SizedBox(width: 12),
              Expanded(child: LabelledTextField(label: 'VIN', controller: _vinCtrl)),
            ],
          ),
          const SizedBox(height: 12),
          LabelledTextField(label: 'Owner', controller: _ownerCtrl),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
