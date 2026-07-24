import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/inventory_model.dart';
import '../../data/repositories/inventory_repository.dart';
import 'vehicle_provider.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(),
);

final inventorySortProvider = StateProvider<String>((ref) => 'Name A–Z');

String _sortToOrderBy(String sort) {
  return switch (sort) {
    'Name A–Z' => 'name ASC',
    'Name Z–A' => 'name DESC',
    'Brand' => 'brand ASC, name ASC',
    'Quantity (High)' => 'quantity DESC',
    'Quantity (Low)' => 'quantity ASC',
    'Date Added' => 'created_at DESC',
    _ => 'name ASC',
  };
}

class InventoryNotifier extends AsyncNotifier<List<InventoryModel>> {
  @override
  Future<List<InventoryModel>> build() async {
    final sort = ref.watch(inventorySortProvider);
    final vehicleId = ref.watch(activeVehicleContextProvider)?.vehicleId;
    return ref.read(inventoryRepositoryProvider).getAll(
          orderBy: _sortToOrderBy(sort),
          vehicleId: vehicleId,
        );
  }

  Future<void> refresh() async {
    final sort = ref.read(inventorySortProvider);
    final vehicleId = ref.read(activeVehicleContextProvider)?.vehicleId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(inventoryRepositoryProvider).getAll(
            orderBy: _sortToOrderBy(sort),
            vehicleId: vehicleId,
          ),
    );
  }

  Future<int> addItem(InventoryModel item) async {
    final id = await ref.read(inventoryRepositoryProvider).insertOrIncrement(item);
    await refresh();
    return id;
  }

  Future<void> updateItem(InventoryModel item) async {
    await ref.read(inventoryRepositoryProvider).update(item);
    await refresh();
  }

  Future<void> deleteItem(int id) async {
    await ref.read(inventoryRepositoryProvider).delete(id);
    await refresh();
  }
}

final inventoryProvider =
    AsyncNotifierProvider<InventoryNotifier, List<InventoryModel>>(
  InventoryNotifier.new,
);

final inventoryItemByIdProvider =
    FutureProvider.autoDispose.family<InventoryModel?, int>((ref, id) {
  return ref.read(inventoryRepositoryProvider).getById(id);
});

final inventorySearchProvider =
    FutureProvider.family<List<InventoryModel>, String>((ref, query) {
  final vehicleId = ref.watch(activeVehicleContextProvider)?.vehicleId;
  if (query.isEmpty) {
    return ref.read(inventoryRepositoryProvider).getAll(vehicleId: vehicleId);
  }
  return ref.read(inventoryRepositoryProvider).search(query, vehicleId: vehicleId);
});

final vehicleInventoryProvider =
    FutureProvider.family<List<InventoryModel>, int>((ref, vehicleId) {
  return ref.read(inventoryRepositoryProvider).getAll(vehicleId: vehicleId);
});

final lowStockProvider = FutureProvider<List<InventoryModel>>((ref) {
  return ref.read(inventoryRepositoryProvider).getLowStock();
});

final compatiblePartsProvider =
    FutureProvider.autoDispose.family<List<InventoryModel>, int>((ref, vehicleId) {
  return ref.read(inventoryRepositoryProvider).getCompatibleWithVehicle(vehicleId);
});
