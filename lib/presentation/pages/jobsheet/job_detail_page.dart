import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:printing/printing.dart';

import '../../../data/models/job_model.dart';
import '../../../data/models/inventory_model.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../services/pdf/pdf_generator.dart';
import '../../providers/job_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/common/app_widgets.dart';

class JobDetailPage extends ConsumerStatefulWidget {
  final int jobId;
  const JobDetailPage({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  final _customerCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  JobStatus _status = JobStatus.open;
  List<JobPartModel> _parts = [];
  bool _initialised = false;
  bool _isSaving = false;
  bool _isExporting = false;

  @override
  void dispose() {
    _customerCtrl.dispose(); _descCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  void _initFromJob(JobModel job) {
    if (_initialised) return;
    _initialised = true;
    _customerCtrl.text = job.customer ?? '';
    _descCtrl.text = job.description ?? '';
    _notesCtrl.text = job.notes ?? '';
    _status = job.status;
    _parts = List.from(job.parts);
  }

  Future<void> _saveJob(JobModel job) async {
    setState(() => _isSaving = true);
    final updated = job.copyWith(
      customer: _customerCtrl.text.trim().isNotEmpty ? _customerCtrl.text.trim() : null,
      description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      status: _status,
      updatedAt: DateTime.now(),
      parts: _parts,
    );
    await ref.read(jobRepositoryProvider).updateJob(updated);
    await ref.read(jobRepositoryProvider).replaceJobParts(job.id!, _parts);
    // Invalidate so the next visit to this job reloads fresh data from DB.
    // _initialised guard keeps the current page showing correctly without a spinner.
    ref.invalidate(jobByIdProvider(widget.jobId));
    await ref.read(vehicleJobsProvider(job.vehicleId).notifier).refresh();
    await ref.read(allJobsProvider.notifier).refresh();
    if (mounted) {
      setState(() => _isSaving = false);
      showSuccessSnackbar(context, 'Job sheet saved!');
    }
  }

  Future<void> _exportPdf(JobModel job, VehicleModel vehicle) async {
    setState(() => _isExporting = true);
    try {
      final generator = PdfGenerator();
      final filePath = await generator.generateJobSheet(job: job, vehicle: vehicle);
      if (mounted) {
        final file = File(filePath);
        await Printing.sharePdf(bytes: await file.readAsBytes(), filename: 'job_${job.id}.pdf');
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Export failed: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _showAddPartDialog(JobModel job) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddPartSheet(jobId: job.id!, onAdd: (part) => setState(() => _parts.add(part)), ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobAsync = ref.watch(jobByIdProvider(widget.jobId));

    return jobAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: ErrorState(message: e.toString())),
      data: (job) {
        if (job == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Job not found.')));
        _initFromJob(job);
        final vehicleAsync = ref.watch(vehicleByIdProvider(job.vehicleId));

        return Scaffold(
          appBar: AppBar(
            title: Text('Job #${job.id?.toString().padLeft(4, '0')}'),
            actions: [
              IconButton(
                icon: _isExporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.picture_as_pdf),
                tooltip: 'Export PDF',
                onPressed: _isExporting ? null : () => vehicleAsync.whenData((v) => v != null ? _exportPdf(job, v) : null),
              ),
              IconButton(
                icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                tooltip: 'Save',
                onPressed: _isSaving ? null : () => _saveJob(job),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                vehicleAsync.when(
                  loading: () => const ShimmerCard(height: 80),
                  error: (_, __) => const SizedBox(),
                  data: (vehicle) => vehicle != null ? _VehicleInfoCard(vehicle: vehicle) : const SizedBox(),
                ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Job Details', style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 12),
                        LabelledTextField(label: 'Customer Name', hint: 'e.g. John Smith', controller: _customerCtrl, prefixIcon: Icons.person_outlined),
                        const SizedBox(height: 12),
                        LabelledTextField(label: 'Description', hint: 'Work to be done...', controller: _descCtrl, maxLines: 2),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<JobStatus>(
                              value: _status,
                              decoration: const InputDecoration(prefixIcon: Icon(Icons.flag_outlined)),
                              items: JobStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))).toList(),
                              onChanged: (v) => setState(() => _status = v ?? _status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LabelledTextField(label: 'Notes', hint: 'Any additional notes...', controller: _notesCtrl, maxLines: 2),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Parts Used', style: theme.textTheme.headlineMedium),
                    TextButton.icon(onPressed: () => _showAddPartDialog(job), icon: const Icon(Icons.add, size: 18), label: const Text('Add Part')),
                  ],
                ),
                const SizedBox(height: 8),
                if (_parts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: Center(child: Column(children: [
                      Icon(Icons.build_outlined, size: 40, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      Text('No parts added yet', style: theme.textTheme.bodyMedium),
                    ])),
                  )
                else
                  ..._parts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final part = entry.value;
                    return _PartRow(
                      part: part,
                      onDelete: () => setState(() => _parts.removeAt(index)),
                      onQtyChanged: (qty) => setState(() => _parts[index] = part.copyWith(quantity: qty)),
                    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1);
                  }),
                const SizedBox(height: 16),
                if (_parts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Parts Used', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        Text(
                          _parts.fold(0, (sum, p) => sum + p.quantity).toString(),
                          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w800, fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _isSaving ? null : () => _saveJob(job),
            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
            label: const Text('Save Job'),
          ),
        );
      },
    );
  }
}

class _VehicleInfoCard extends StatelessWidget {
  final VehicleModel vehicle;
  const _VehicleInfoCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(6)),
            child: Text(vehicle.registration, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vehicle.displayTitle, style: theme.textTheme.headlineSmall),
              if (vehicle.year != null || vehicle.fuelType != null)
                Text([vehicle.year, vehicle.fuelType].whereType<String>().join(' • '), style: theme.textTheme.bodySmall),
            ],
          )),
        ]),
      ),
    );
  }
}

class _PartRow extends StatelessWidget {
  final JobPartModel part;
  final VoidCallback onDelete;
  final ValueChanged<int> onQtyChanged;
  const _PartRow({required this.part, required this.onDelete, required this.onQtyChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(part.name, style: theme.textTheme.titleMedium),
              if (part.brand != null || part.partNumber != null)
                Text([part.brand, part.partNumber].whereType<String>().join(' • '), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
            ],
          )),
          Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: part.quantity > 1 ? () => onQtyChanged(part.quantity - 1) : null, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
            Text('${part.quantity}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () => onQtyChanged(part.quantity + 1), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
          ]),
          IconButton(icon: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 20), onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
        ]),
      ),
    );
  }
}

class _AddPartSheet extends ConsumerStatefulWidget {
  final int jobId;
  final ValueChanged<JobPartModel> onAdd;
  final WidgetRef ref;
  const _AddPartSheet({required this.jobId, required this.onAdd, required this.ref});

  @override
  ConsumerState<_AddPartSheet> createState() => _AddPartSheetState();
}

class _AddPartSheetState extends ConsumerState<_AddPartSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _partNumCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose(); _brandCtrl.dispose(); _partNumCtrl.dispose(); _searchCtrl.dispose();
    super.dispose();
  }

  void _addManual() {
    if (_nameCtrl.text.trim().isEmpty) return;
    widget.onAdd(JobPartModel(jobId: widget.jobId, name: _nameCtrl.text.trim(), brand: _brandCtrl.text.trim().isNotEmpty ? _brandCtrl.text.trim() : null, partNumber: _partNumCtrl.text.trim().isNotEmpty ? _partNumCtrl.text.trim() : null));
    Navigator.of(context).pop();
  }

  void _addFromInventory(InventoryModel item) {
    widget.onAdd(JobPartModel(jobId: widget.jobId, inventoryId: item.id, name: item.name, brand: item.brand, partNumber: item.partNumber));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inventoryAsync = _searchQuery.isEmpty ? ref.watch(inventoryProvider) : ref.watch(inventorySearchProvider(_searchQuery));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              Text('Add Part', style: theme.textTheme.headlineMedium),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ]),
          ),
          TabBar(controller: _tabController, tabs: const [Tab(text: 'From Inventory'), Tab(text: 'Manual Entry')]),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(controller: _searchCtrl, decoration: const InputDecoration(hintText: 'Search inventory...', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() => _searchQuery = v)),
                  ),
                  Expanded(child: inventoryAsync.when(
                    loading: () => const ShimmerList(count: 3),
                    error: (e, _) => ErrorState(message: e.toString()),
                    data: (items) => items.isEmpty
                      ? const EmptyState(icon: Icons.inventory_2_outlined, title: 'No items found', subtitle: 'Scan parts to add them to inventory.')
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final item = items[i];
                            return ListTile(
                              leading: PartPhoto(imagePath: item.imagePath, size: 40),
                              title: Text(item.name),
                              subtitle: Text([item.brand, item.partNumber].whereType<String>().join(' • ')),
                              trailing: Text('x${item.quantity}', style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                              onTap: () => _addFromInventory(item),
                            );
                          },
                        ),
                  )),
                ]),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    LabelledTextField(label: 'Part Name *', hint: 'e.g. Oil Filter', controller: _nameCtrl, prefixIcon: Icons.build_outlined),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: LabelledTextField(label: 'Brand', controller: _brandCtrl, prefixIcon: Icons.business_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: LabelledTextField(label: 'Part Number', controller: _partNumCtrl, prefixIcon: Icons.tag)),
                    ]),
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _addManual, icon: const Icon(Icons.add), label: const Text('Add to Job'))),
                  ]),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
