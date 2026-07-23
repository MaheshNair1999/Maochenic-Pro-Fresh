import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/job_model.dart';
import '../../providers/job_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/common/app_widgets.dart';

class JobListPage extends ConsumerWidget {
  const JobListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(allJobsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Sheets'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(allJobsProvider))],
      ),
      body: jobsAsync.when(
        loading: () => const ShimmerList(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(allJobsProvider)),
        data: (jobs) {
          if (jobs.isEmpty) {
            return EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No job sheets yet',
            subtitle: 'Open a vehicle and create a job to get started.',
            action: ElevatedButton.icon(onPressed: () => context.go(AppRoutes.vehicles), icon: const Icon(Icons.directions_car), label: const Text('Go to Vehicles')),
          );
          }
          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 100),
              itemCount: jobs.length,
              itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(verticalOffset: 50, child: FadeInAnimation(child: _JobSummaryCard(job: jobs[index]))),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _JobSummaryCard extends ConsumerWidget {
  final JobModel job;
  const _JobSummaryCard({required this.job});

  Color _statusColor(JobStatus s) => switch (s) {
    JobStatus.open => const Color(0xFF1B4F72),
    JobStatus.inProgress => const Color(0xFFF39C12),
    JobStatus.completed => const Color(0xFF1E8449),
    JobStatus.cancelled => const Color(0xFFC0392B),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd MMM yyyy').format(job.date);
    final vehicleAsync = ref.watch(vehicleByIdProvider(job.vehicleId));

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('${AppRoutes.jobs}/${job.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: vehicleAsync.when(
                  loading: () => const ShimmerCard(height: 20),
                  error: (_, __) => Text('Job #${job.id}', style: theme.textTheme.headlineSmall),
                  data: (vehicle) => Text(vehicle?.displayTitle ?? 'Unknown Vehicle', style: theme.textTheme.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
                StatusChip(label: job.status.displayName, color: _statusColor(job.status)),
              ]),
              const SizedBox(height: 8),
              vehicleAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (vehicle) => vehicle != null ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(vehicle.registration, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, letterSpacing: 1)),
                ) : const SizedBox(),
              ),
              const SizedBox(height: 8),
              Row(children: [
                if (job.customer != null) ...[
                  Icon(Icons.person_outlined, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(job.customer!, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                ],
                Icon(Icons.calendar_today_outlined, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(dateStr, style: theme.textTheme.bodySmall),
                const Spacer(),
                Icon(Icons.build_outlined, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text('${job.totalPartsCount} part(s)', style: theme.textTheme.bodySmall),
              ]),
              if (job.parts.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...job.parts.take(4).map((part) => Chip(label: Text('${part.name} x${part.quantity}'), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact)),
                    if (job.parts.length > 4) Chip(label: Text('+${job.parts.length - 4} more'), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
