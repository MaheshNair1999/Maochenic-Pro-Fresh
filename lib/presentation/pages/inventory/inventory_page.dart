import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/inventory_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/common/app_widgets.dart';

/// Inventory list with search, sort, and category filter.
class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sort = ref.watch(inventorySortProvider);
    final vehicleContext = ref.watch(activeVehicleContextProvider);

    final itemsAsync = _searchQuery.isEmpty
        ? ref.watch(inventoryProvider)
        : ref.watch(inventorySearchProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: Text(vehicleContext == null
            ? 'Inventory'
            : '${vehicleContext.displayName} Parts'),
        actions: [
          // Sort button
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (value) =>
                ref.read(inventorySortProvider.notifier).state = value,
            itemBuilder: (_) => AppConstants.inventorySortOptions
                .map((option) => PopupMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          if (sort == option)
                            const Icon(Icons.check, size: 16)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(option),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, brand, part number…',
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

          // ── Low stock alert ─────────────────────────────────────────
          ref.watch(lowStockProvider).maybeWhen(
                data: (lowItems) => lowItems.isEmpty
                    ? const SizedBox.shrink()
                    : Container(
                        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39C12).withValues(alpha: 0.12),
                          border: Border.all(color: const Color(0xFFF39C12).withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF39C12), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${lowItems.length} item(s) low on stock / Χαμηλό απόθεμα',
                              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFB9770E), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ]),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),

          // ── Sort label ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Icon(Icons.sort, size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(
                  'Sorted by: $sort',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // ── List ─────────────────────────────────────────────────────
          Expanded(
            child: itemsAsync.when(
              loading: () => const ShimmerList(),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(inventoryProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: _searchQuery.isEmpty
                        ? 'Inventory is empty'
                        : 'No results',
                    subtitle: _searchQuery.isEmpty
                        ? 'Scan a spare part to add it here.'
                        : 'Try a different search term.',
                  );
                }

                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50,
                          child: FadeInAnimation(
                            child: _InventoryCard(item: items[index]),
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
    );
  }
}

class _InventoryCard extends ConsumerWidget {
  final InventoryModel item;
  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDeleteConfirmation(
        context,
        title: 'Remove from Inventory',
        content: 'Delete "${item.name}" from inventory?',
      ),
      onDismissed: (_) {
        ref.read(inventoryProvider.notifier).deleteItem(item.id!);
        showSuccessSnackbar(context, '${item.name} removed');
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('${AppRoutes.inventory}/${item.id}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Photo
                PartPhoto(imagePath: item.imagePath, size: 60),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.headlineSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.nameGr != null)
                        Text(
                          item.nameGr!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (item.compatibility != null)
                        Text(
                          item.compatibility!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      if (item.brand != null)
                        Text(
                          item.brand!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      if (item.partNumber != null)
                        Text(
                          'PN: ${item.partNumber}',
                          style: theme.textTheme.bodySmall,
                        ),
                      if (item.oemNumber != null)
                        Text(
                          'OEM: ${item.oemNumber}',
                          style: theme.textTheme.bodySmall,
                        ),
                      if (item.category != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Chip(
                            label: Text(item.category!),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ),

                // Quantity badge (green = ok, amber = low stock, red = empty)
                Column(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: (item.quantity <= 0
                                ? theme.colorScheme.error
                                : item.isLowStock
                                    ? const Color(0xFFF39C12)
                                    : const Color(0xFF1E8449))
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${item.quantity}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: item.quantity <= 0
                                ? theme.colorScheme.error
                                : item.isLowStock
                                    ? const Color(0xFFB9770E)
                                    : const Color(0xFF1E8449),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (item.isLowStock)
                      const Icon(Icons.warning_amber_rounded,
                          size: 14, color: Color(0xFFF39C12))
                    else
                      Text('qty', style: theme.textTheme.bodySmall),
                  ],
                ),

                const SizedBox(width: 8),
                Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
