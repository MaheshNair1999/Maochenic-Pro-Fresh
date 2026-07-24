import '../../core/constants/app_constants.dart';
import '../datasources/local/database_helper.dart';
import '../models/inventory_model.dart';

class InventoryRepository {
  final DatabaseHelper _db;

  InventoryRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  Future<int> insertOrIncrement(InventoryModel item) async {
    if (item.partNumber != null && item.partNumber!.isNotEmpty) {
      final existing = await getByPartNumber(item.partNumber!, vehicleId: item.vehicleId);
      if (existing != null) {
        await update(existing.copyWith(quantity: existing.quantity + 1, updatedAt: DateTime.now()));
        return existing.id!;
      }
    }
    return insert(item);
  }

  Future<int> insert(InventoryModel item) async {
    final now = DateTime.now();
    return _db.insert(AppConstants.tableInventory, item.copyWith(createdAt: now, updatedAt: now).toMap());
  }

  Future<int> update(InventoryModel item) async {
    return _db.update(
      AppConstants.tableInventory,
      item.copyWith(updatedAt: DateTime.now()).toMap(),
      'id = ?',
      [item.id],
    );
  }

  Future<int> delete(int id) async {
    return _db.delete(AppConstants.tableInventory, 'id = ?', [id]);
  }

  Future<List<InventoryModel>> getAll({String orderBy = 'name ASC', int? vehicleId}) async {
    final rows = await _db.query(
      AppConstants.tableInventory,
      where: vehicleId == null ? null : 'vehicle_id = ?',
      whereArgs: vehicleId == null ? null : [vehicleId],
      orderBy: orderBy,
    );
    return rows.map(InventoryModel.fromMap).toList();
  }

  Future<InventoryModel?> getById(int id) async {
    final rows = await _db.query(AppConstants.tableInventory, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return InventoryModel.fromMap(rows.first);
  }

  Future<InventoryModel?> getByPartNumber(String partNumber, {int? vehicleId}) async {
    final rows = await _db.query(
      AppConstants.tableInventory,
      where: vehicleId == null ? 'part_number = ? AND vehicle_id IS NULL' : 'part_number = ? AND vehicle_id = ?',
      whereArgs: vehicleId == null ? [partNumber] : [partNumber, vehicleId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return InventoryModel.fromMap(rows.first);
  }

  Future<List<InventoryModel>> search(String query, {int? vehicleId}) async {
    final q = '%$query%';
    final vehicleFilter = vehicleId == null ? '' : ' AND vehicle_id = ?';
    final rows = await _db.query(
      AppConstants.tableInventory,
      where: '(name LIKE ? OR name_gr LIKE ? OR brand LIKE ? OR part_number LIKE ? OR oem_number LIKE ? OR compatibility LIKE ?)$vehicleFilter',
      whereArgs: vehicleId == null ? [q, q, q, q, q, q] : [q, q, q, q, q, q, vehicleId],
      orderBy: 'name ASC',
    );
    return rows.map(InventoryModel.fromMap).toList();
  }

  /// Items where min_quantity > 0 AND quantity <= min_quantity.
  Future<List<InventoryModel>> getLowStock() async {
    final rows = await _db.query(
      AppConstants.tableInventory,
      where: 'min_quantity > 0 AND quantity <= min_quantity',
      orderBy: 'quantity ASC',
    );
    return rows.map(InventoryModel.fromMap).toList();
  }

  /// All inventory items compatible with a given vehicle (filter in Dart).
  Future<List<InventoryModel>> getCompatibleWithVehicle(int vehicleId) async {
    final all = await getAll();
    return all.where((item) => item.compatibleVehicleIds.contains(vehicleId)).toList();
  }

  /// Adjusts stock quantity by [delta] (positive = add, negative = remove).
  /// Clamps at 0 — stock cannot go below zero.
  Future<void> adjustQuantity(int id, int delta) async {
    final item = await getById(id);
    if (item == null) return;
    final newQty = (item.quantity + delta).clamp(0, 99999);
    await _db.update(
      AppConstants.tableInventory,
      {'quantity': newQty, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      'id = ?',
      [id],
    );
  }
}
