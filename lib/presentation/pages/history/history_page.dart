import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/job_model.dart';
import '../../providers/job_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/common/app_widgets.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  JobStatus? _statusFilter;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = _searchQuery.isEmpty ? ref.watch(allJobsProvider) : ref.watch(jobSearchProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          PopupMenuButton<JobStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _statusFilter = v),
            itemBuilder: (_) => [
              PopupMenuItem(value: null, child: Row(children: [if (_statusFilter == null) const Icon(Icons.check, size: 16) else const SizedBox(width: 16), const SizedBox(width: 8), const Text('All')])),
              ...JobStatus.values.map((s) => PopupMenuItem(value: s, child: Row(children: [if (_statusFilter == s) const Icon(Icons.check, size: 16) else const SizedBox(width: 16), const SizedBox(width: 8), Text(s.displayName)]))),
            ],
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by customer, vehicle...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); }) : null,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ).animate().fadeIn(duration: 300.ms),
        if (_statusFilter != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              Chip(label: Text('Status: ${_statusFilter!.displayName}'), deleteIcon: const Icon(Icons.close, size: 16), onDeleted: () => setState(() => _statusFilter = null), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact),
            ]),
          ),
        Expanded(
          child: jobsAsync.when(
            loading: () => const ShimmerList(),
            error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(allJobsProvider)),
            data: (jobs) {
              final filtered = _statusFilter != null ? jobs.where((j) => j.status == _statusFilter).toList() : jobs;
              if (filtered.isEmpty) {
                return EmptyState(
                icon: Icons.history,
                title: _searchQuery.isEmpty ? 'No history yet' : 'No results',
                subtitle: _searchQuery.isEmpty ? 'Completed jobs will appear here.' : 'Try a different search term.',
              );
              }
              return AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 12, bottom: 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(verticalOffset: 50, child: FadeInAnimation(child: _HistoryCard(job: filtered[index]))),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  final JobModel job;
  const _HistoryCard({required this.job});

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
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 4, height: 52, decoration: BoxDecoration(color: _statusColor(job.status), borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: vehicleAsync.when(
                    loading: () => const ShimmerCard(height: 16),
                    error: (_, __) => Text('Job #${job.id}'),
                    data: (v) => Text(v?.displayTitle ?? 'Unknown Vehicle', style: theme.textTheme.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
                  StatusChip(label: job.status.displayName, color: _statusColor(job.status)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  if (job.customer != null) ...[
                    Icon(Icons.person_outlined, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 3),
                    Text(job.customer!, style: theme.textTheme.bodySmall),
                    const SizedBox(width: 10),
                  ],
                  Icon(Icons.event, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 3),
                  Text(dateStr, style: theme.textTheme.bodySmall),
                  const Spacer(),
                  Text('${job.totalPartsCount} part(s)', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                ]),
              ],
            )),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          ]),
        ),
      ),
    );
  }
}
