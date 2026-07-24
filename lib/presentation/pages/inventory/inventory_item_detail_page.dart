import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/inventory_model.dart';
import '../../../data/models/stock_movement_model.dart';
import '../../../data/models/vehicle_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/stock_movement_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/common/app_widgets.dart';

class InventoryItemDetailPage extends ConsumerWidget {
  final int itemId;
  const InventoryItemDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(inventoryItemByIdProvider(itemId));
    return itemAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: ErrorState(message: e.toString())),
      data: (item) {
        if (item == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Item not found.')));
        return _ItemDetailView(item: item);
      },
    );
  }
}

class _ItemDetailView extends ConsumerStatefulWidget {
  final InventoryModel item;
  const _ItemDetailView({required this.item});

  @override
  ConsumerState<_ItemDetailView> createState() => _ItemDetailViewState();
}

class _ItemDetailViewState extends ConsumerState<_ItemDetailView> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _nameGrCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _partNumCtrl;
  late final TextEditingController _oemCtrl;
  late final TextEditingController _compatibilityCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _minQtyCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _descGrCtrl;
  late final TextEditingController _notesCtrl;
  String? _selectedCategory;
  late List<int> _compatibleVehicleIds;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item.name);
    _nameGrCtrl = TextEditingController(text: item.nameGr ?? '');
    _brandCtrl = TextEditingController(text: item.brand ?? '');
    _partNumCtrl = TextEditingController(text: item.partNumber ?? '');
    _oemCtrl = TextEditingController(text: item.oemNumber ?? '');
    _compatibilityCtrl = TextEditingController(text: item.compatibility ?? '');
    _quantityCtrl = TextEditingController(text: item.quantity.toString());
    _minQtyCtrl = TextEditingController(text: item.minQuantity.toString());
    _descCtrl = TextEditingController(text: item.description ?? '');
    _descGrCtrl = TextEditingController(text: item.descriptionGr ?? '');
    _notesCtrl = TextEditingController(text: item.notes ?? '');
    _selectedCategory = item.category;
    _compatibleVehicleIds = List.from(item.compatibleVehicleIds);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _nameGrCtrl.dispose(); _brandCtrl.dispose();
    _partNumCtrl.dispose(); _oemCtrl.dispose(); _compatibilityCtrl.dispose();
    _quantityCtrl.dispose(); _minQtyCtrl.dispose();
    _descCtrl.dispose(); _descGrCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final qty = int.tryParse(_quantityCtrl.text.trim()) ?? widget.item.quantity;
    final minQty = int.tryParse(_minQtyCtrl.text.trim()) ?? widget.item.minQuantity;
    setState(() => _isSaving = true);

    final updated = widget.item.copyWith(
      name: _nameCtrl.text.trim(),
      nameGr: _nameGrCtrl.text.trim().isNotEmpty ? _nameGrCtrl.text.trim() : null,
      brand: _brandCtrl.text.trim().isNotEmpty ? _brandCtrl.text.trim() : null,
      partNumber: _partNumCtrl.text.trim().isNotEmpty ? _partNumCtrl.text.trim() : null,
      oemNumber: _oemCtrl.text.trim().isNotEmpty ? _oemCtrl.text.trim() : null,
      category: _selectedCategory,
      compatibility: _compatibilityCtrl.text.trim().isNotEmpty
          ? _compatibilityCtrl.text.trim()
          : null,
      description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      descriptionGr: _descGrCtrl.text.trim().isNotEmpty ? _descGrCtrl.text.trim() : null,
      quantity: qty,
      minQuantity: minQty,
      compatibleVehicleIds: _compatibleVehicleIds,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    );
    await ref.read(inventoryProvider.notifier).updateItem(updated);

    // Log a manual stock movement if quantity changed
    final delta = qty - widget.item.quantity;
    if (delta != 0) {
      await ref.read(stockMovementRepositoryProvider).insert(StockMovementModel(
            inventoryId: widget.item.id!,
            type: delta > 0 ? 'manual_in' : 'manual_out',
            quantityChange: delta,
            notes: 'Manual adjustment / Χειροκίνητη αλλαγή',
            createdAt: DateTime.now(),
          ));
    }

    ref.invalidate(inventoryItemByIdProvider(widget.item.id!));
    ref.invalidate(itemMovementsProvider(widget.item.id!));
    ref.invalidate(lowStockProvider);
    if (mounted) {
      setState(() { _isEditing = false; _isSaving = false; });
      showSuccessSnackbar(context, 'Item updated!');
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDeleteConfirmation(context, title: 'Delete Item', content: 'Remove "${widget.item.name}" from inventory?');
    if (confirmed && mounted) {
      await ref.read(inventoryProvider.notifier).deleteItem(widget.item.id!);
      if (!mounted) return;
      context.pop();
    }
  }

  Future<void> _editCompatibleVehicles() async {
    final vehicles = ref.read(vehicleListProvider).value ?? [];
    if (vehicles.isEmpty) {
      showErrorSnackbar(context, 'No vehicles registered yet.');
      return;
    }
    final selected = Set<int>.from(_compatibleVehicleIds);
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _VehiclePickerSheet(vehicles: vehicles, initiallySelected: selected),
    );
    if (result != null) {
      setState(() => _compatibleVehicleIds = result.toList());
      if (!_isEditing) {
        // Persist immediately when not in edit mode
        final updated = widget.item.copyWith(compatibleVehicleIds: _compatibleVehicleIds);
        await ref.read(inventoryProvider.notifier).updateItem(updated);
        ref.invalidate(inventoryItemByIdProvider(widget.item.id!));
        if (mounted) showSuccessSnackbar(context, 'Compatibility updated!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final movementsAsync = ref.watch(itemMovementsProvider(item.id!));
    final vehiclesAsync = ref.watch(vehicleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          if (!_isEditing) IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _isEditing = true)),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imagePath != null && File(item.imagePath!).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(item.imagePath!), width: double.infinity, height: 220, fit: BoxFit.cover),
              ).animate().fadeIn(duration: 400.ms)
            else
              Container(
                height: 140,
                decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
                child: Center(child: Icon(Icons.build, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3))),
              ),
            const SizedBox(height: 16),

            // ── Low stock warning ─────────────────────────────────────────
            if (item.isLowStock)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF39C12).withValues(alpha: 0.12),
                  border: Border.all(color: const Color(0xFFF39C12).withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFF39C12)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Low stock! Only ${item.quantity} left (min: ${item.minQuantity})\nΧαμηλό απόθεμα! Απομένουν μόνο ${item.quantity}',
                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFB9770E)),
                  )),
                ]),
              ),

            _QuantityStepper(
              quantity: int.tryParse(_quantityCtrl.text) ?? item.quantity,
              onChanged: (v) => setState(() => _quantityCtrl.text = v.toString()),
            ),
            const SizedBox(height: 20),

            if (!_isEditing) ...[
              _ReadField('Name', item.name, Icons.build_outlined),
              if (item.nameGr != null) _ReadField('Όνομα (GR)', item.nameGr!, Icons.translate),
              _ReadField('Brand', item.brand ?? '—', Icons.business_outlined),
              _ReadField('Part Number', item.partNumber ?? '—', Icons.tag),
              _ReadField('OEM Number', item.oemNumber ?? '—', Icons.confirmation_number_outlined),
              _ReadField('Category', item.category ?? '—', Icons.category_outlined),
              _ReadField('Compatibility', item.compatibility ?? '—', Icons.directions_car_outlined),
              if (item.description != null) _ReadField('Description', item.description!, Icons.description_outlined),
              if (item.descriptionGr != null) _ReadField('Περιγραφή (GR)', item.descriptionGr!, Icons.description_outlined),
              _ReadField('Min. Stock Alert', item.minQuantity > 0 ? '${item.minQuantity}' : 'Off', Icons.notification_important_outlined),
              _ReadField(
                'Confidence',
                item.confidenceScore == null
                    ? '—'
                    : '${(item.confidenceScore! * 100).toStringAsFixed(0)}%',
                Icons.auto_awesome,
              ),
              _ReadField('Notes', item.notes ?? '—', Icons.notes),
            ] else ...[
              LabelledTextField(label: 'Name (English)', controller: _nameCtrl, prefixIcon: Icons.build_outlined),
              const SizedBox(height: 12),
              LabelledTextField(label: 'Όνομα (Ελληνικά)', controller: _nameGrCtrl, prefixIcon: Icons.translate),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: LabelledTextField(label: 'Brand', controller: _brandCtrl, prefixIcon: Icons.business_outlined)),
                const SizedBox(width: 12),
                Expanded(child: LabelledTextField(label: 'Part Number', controller: _partNumCtrl, prefixIcon: Icons.tag)),
              ]),
              const SizedBox(height: 12),
              LabelledTextField(label: 'OEM Number', controller: _oemCtrl, prefixIcon: Icons.confirmation_number_outlined),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: AppConstants.partCategories.contains(_selectedCategory) ? _selectedCategory : null,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
                    hint: const Text('Select category'),
                    isExpanded: true,
                    items: AppConstants.partCategories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(AppConstants.partCategoryGr[c] == null
                                  ? c
                                  : '$c / ${AppConstants.partCategoryGr[c]}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LabelledTextField(label: 'Compatibility', controller: _compatibilityCtrl, prefixIcon: Icons.directions_car_outlined),
              const SizedBox(height: 12),
              LabelledTextField(label: 'Description (English)', controller: _descCtrl, maxLines: 2),
              const SizedBox(height: 12),
              LabelledTextField(label: 'Περιγραφή (Ελληνικά)', controller: _descGrCtrl, maxLines: 2),
              const SizedBox(height: 12),
              LabelledTextField(
                label: 'Min. Stock Alert (0 = off)',
                controller: _minQtyCtrl,
                prefixIcon: Icons.notification_important_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              LabelledTextField(label: 'Notes', controller: _notesCtrl, maxLines: 3),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() => _isEditing = false), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
                )),
              ]),
            ],

            const SizedBox(height: 24),

            // ── Compatible vehicles ───────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Compatible Vehicles', style: theme.textTheme.headlineSmall),
                TextButton.icon(
                  onPressed: _editCompatibleVehicles,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            vehiclesAsync.when(
              loading: () => const ShimmerCard(height: 48),
              error: (_, __) => const SizedBox(),
              data: (vehicles) {
                final compatible = vehicles.where((v) => _compatibleVehicleIds.contains(v.id)).toList();
                if (compatible.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'No linked vehicles. Tap Edit to link.\nΚανένα συνδεδεμένο όχημα.',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: compatible
                      .map((v) => Chip(
                            avatar: const Icon(Icons.directions_car, size: 16),
                            label: Text('${v.displayTitle} • ${v.registration}'),
                          ))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Stock movement history ────────────────────────────────────
            Text('Stock History / Ιστορικό Αποθέματος', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            movementsAsync.when(
              loading: () => const ShimmerCard(height: 60),
              error: (_, __) => const SizedBox(),
              data: (movements) {
                if (movements.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: Text('No stock movements yet.', style: theme.textTheme.bodySmall),
                  );
                }
                return Column(
                  children: movements.map((m) => _MovementRow(movement: m)).toList(),
                );
              },
            ),
            const SizedBox(height: 40),
          ].animate(interval: 40.ms).fadeIn(duration: 300.ms),
        ),
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  final StockMovementModel movement;
  const _MovementRow({required this.movement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = movement.isPositive;
    final color = positive ? const Color(0xFF1E8449) : const Color(0xFFC0392B);
    final dateStr = DateFormat('dd MMM yyyy • HH:mm').format(movement.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(positive ? Icons.arrow_downward : Icons.arrow_upward, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(movement.typeLabel, style: theme.textTheme.titleSmall),
            Text(dateStr, style: theme.textTheme.bodySmall),
          ],
        )),
        Text(
          '${positive ? '+' : ''}${movement.quantityChange}',
          style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w800),
        ),
      ]),
    );
  }
}

class _VehiclePickerSheet extends StatefulWidget {
  final List<VehicleModel> vehicles;
  final Set<int> initiallySelected;
  const _VehiclePickerSheet({required this.vehicles, required this.initiallySelected});

  @override
  State<_VehiclePickerSheet> createState() => _VehiclePickerSheetState();
}

class _VehiclePickerSheetState extends State<_VehiclePickerSheet> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initiallySelected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            Expanded(child: Text('Compatible Vehicles\nΣυμβατά Οχήματα', style: theme.textTheme.headlineSmall)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.vehicles.length,
            itemBuilder: (_, i) {
              final v = widget.vehicles[i];
              final checked = _selected.contains(v.id);
              return CheckboxListTile(
                value: checked,
                title: Text(v.displayTitle),
                subtitle: Text(v.registration),
                secondary: const Icon(Icons.directions_car),
                onChanged: (val) => setState(() {
                  if (val == true) {
                    _selected.add(v.id!);
                  } else {
                    _selected.remove(v.id);
                  }
                }),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              child: const Text('Done / Τέλος'),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ReadField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ReadField(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text(value, style: theme.textTheme.titleMedium),
          ])),
        ]),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  const _QuantityStepper({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Quantity in Stock', style: theme.textTheme.titleMedium),
          Row(children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline), color: theme.colorScheme.primary, onPressed: quantity > 0 ? () => onChanged(quantity - 1) : null),
            Text('$quantity', style: theme.textTheme.headlineLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800)),
            IconButton(icon: const Icon(Icons.add_circle_outline), color: theme.colorScheme.primary, onPressed: () => onChanged(quantity + 1)),
          ]),
        ],
      ),
    );
  }
}
