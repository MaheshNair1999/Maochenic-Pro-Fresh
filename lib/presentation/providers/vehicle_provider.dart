import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/vehicle_model.dart';
import '../../data/models/vehicle_context.dart';
import '../../data/repositories/vehicle_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────────
final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => VehicleRepository(),
);

// ── Vehicle list ──────────────────────────────────────────────────────────────

class VehicleListNotifier extends AsyncNotifier<List<VehicleModel>> {
  @override
  Future<List<VehicleModel>> build() async {
    return ref.read(vehicleRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(vehicleRepositoryProvider).getAll(),
    );
  }

  Future<int> addVehicle(VehicleModel vehicle) async {
    final repo = ref.read(vehicleRepositoryProvider);
    final id = await repo.insert(vehicle);
    await refresh();
    return id;
  }

  Future<void> updateVehicle(VehicleModel vehicle) async {
    await ref.read(vehicleRepositoryProvider).update(vehicle);
    await refresh();
  }

  Future<void> deleteVehicle(int id) async {
    await ref.read(vehicleRepositoryProvider).delete(id);
    await refresh();
  }
}

final vehicleListProvider =
    AsyncNotifierProvider<VehicleListNotifier, List<VehicleModel>>(
  VehicleListNotifier.new,
);

// ── Single vehicle ────────────────────────────────────────────────────────────

final vehicleByIdProvider =
    FutureProvider.family<VehicleModel?, int>((ref, id) {
  return ref.read(vehicleRepositoryProvider).getById(id);
});

// Active vehicle context used by AI and vehicle-aware workflows.
final activeVehicleContextProvider =
    StateProvider<VehicleContext?>((ref) => null);

final vehicleContextByIdProvider =
    FutureProvider.family<VehicleContext?, int>((ref, id) async {
  final vehicle = await ref.read(vehicleRepositoryProvider).getById(id);
  return vehicle == null ? null : VehicleContext.fromVehicle(vehicle);
});

// ── Search ────────────────────────────────────────────────────────────────────

final vehicleSearchProvider =
    FutureProvider.family<List<VehicleModel>, String>((ref, query) {
  if (query.isEmpty) {
    return ref.read(vehicleRepositoryProvider).getAll();
  }
  return ref.read(vehicleRepositoryProvider).search(query);
});
