import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/inventory_model.dart';
import '../../providers/inventory_provider.dart';
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
  late final TextEditingController _brandCtrl;
  late final TextEditingController _partNumCtrl;
  late final TextEditingController _oemCtrl;
  late final TextEditingController _compatibilityCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _notesCtrl;
  String? _selectedCategory;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item.name);
    _brandCtrl = TextEditingController(text: item.brand ?? '');
    _partNumCtrl = TextEditingController(text: item.partNumber ?? '');
    _oemCtrl = TextEditingController(text: item.oemNumber ?? '');
    _compatibilityCtrl = TextEditingController(text: item.compatibility ?? '');
    _quantityCtrl = TextEditingController(text: item.quantity.toString());
    _notesCtrl = TextEditingController(text: item.notes ?? '');
    _selectedCategory = item.category;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _brandCtrl.dispose(); _partNumCtrl.dispose();
    _oemCtrl.dispose(); _compatibilityCtrl.dispose();
    _quantityCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final qty = int.tryParse(_quantityCtrl.text.trim()) ?? widget.item.quantity;
    setState(() => _isSaving = true);
    final updated = widget.item.copyWith(
      name: _nameCtrl.text.trim(),
      brand: _brandCtrl.text.trim().isNotEmpty ? _brandCtrl.text.trim() : null,
      partNumber: _partNumCtrl.text.trim().isNotEmpty ? _partNumCtrl.text.trim() : null,
      oemNumber: _oemCtrl.text.trim().isNotEmpty ? _oemCtrl.text.trim() : null,
      category: _selectedCategory,
      compatibility: _compatibilityCtrl.text.trim().isNotEmpty
          ? _compatibilityCtrl.text.trim()
          : null,
      quantity: qty,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    );
    await ref.read(inventoryProvider.notifier).updateItem(updated);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
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
            const SizedBox(height: 24),
            _QuantityStepper(
              quantity: int.tryParse(_quantityCtrl.text) ?? item.quantity,
              onChanged: (v) => setState(() => _quantityCtrl.text = v.toString()),
            ),
            const SizedBox(height: 20),
            if (!_isEditing) ...[
              _ReadField('Name', item.name, Icons.build_outlined),
              _ReadField('Brand', item.brand ?? '—', Icons.business_outlined),
              _ReadField('Part Number', item.partNumber ?? '—', Icons.tag),
              _ReadField('OEM Number', item.oemNumber ?? '—', Icons.confirmation_number_outlined),
              _ReadField('Category', item.category ?? '—', Icons.category_outlined),
              _ReadField('Compatibility', item.compatibility ?? '—', Icons.directions_car_outlined),
              _ReadField(
                'Confidence',
                item.confidenceScore == null
                    ? '—'
                    : '${(item.confidenceScore! * 100).toStringAsFixed(0)}%',
                Icons.auto_awesome,
              ),
              _ReadField('Notes', item.notes ?? '—', Icons.notes),
            ] else ...[
              LabelledTextField(label: 'Name', controller: _nameCtrl, prefixIcon: Icons.build_outlined),
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
                    initialValue: AppConstants.partCategories.contains(_selectedCategory) ? _selectedCategory : null,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
                    hint: const Text('Select category'),
                    isExpanded: true,
                    items: AppConstants.partCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LabelledTextField(label: 'Compatibility', controller: _compatibilityCtrl, prefixIcon: Icons.directions_car_outlined),
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
          ].animate(interval: 50.ms).fadeIn(duration: 300.ms),
        ),
      ),
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
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text(value, style: theme.textTheme.titleMedium),
          ]),
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
