import '../../core/constants/app_constants.dart';
import '../datasources/local/database_helper.dart';
import '../models/inventory_model.dart';

/// Data access layer for inventory items.
class InventoryRepository {
  final DatabaseHelper _db;

  InventoryRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  /// Inserts a new part, or increments quantity if the same part is already
  /// stored for the same vehicle.
  /// Returns the id of the row (inserted or existing).
  Future<int> insertOrIncrement(InventoryModel item) async {
    if (item.partNumber != null && item.partNumber!.isNotEmpty) {
      final existing = await getByPartNumber(
        item.partNumber!,
        vehicleId: item.vehicleId,
      );
      if (existing != null) {
        await update(existing.copyWith(
          quantity: existing.quantity + 1,
          updatedAt: DateTime.now(),
        ));
        return existing.id!;
      }
    }
    return insert(item);
  }

  Future<int> insert(InventoryModel item) async {
    final now = DateTime.now();
    final row = item.copyWith(createdAt: now, updatedAt: now).toMap();
    return _db.insert(AppConstants.tableInventory, row);
  }

  Future<int> update(InventoryModel item) async {
    final row = item.copyWith(updatedAt: DateTime.now()).toMap();
    return _db.update(
      AppConstants.tableInventory,
      row,
      'id = ?',
      [item.id],
    );
  }

  Future<int> delete(int id) async {
    return _db.delete(AppConstants.tableInventory, 'id = ?', [id]);
  }

  /// Fetches all inventory items with optional sort.
  Future<List<InventoryModel>> getAll({
    String orderBy = 'name ASC',
    int? vehicleId,
  }) async {
    final rows = await _db.query(
      AppConstants.tableInventory,
      where: vehicleId == null ? null : 'vehicle_id = ?',
      whereArgs: vehicleId == null ? null : [vehicleId],
      orderBy: orderBy,
    );
    return rows.map(InventoryModel.fromMap).toList();
  }

  Future<InventoryModel?> getById(int id) async {
    final rows = await _db.query(
      AppConstants.tableInventory,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return InventoryModel.fromMap(rows.first);
  }

  Future<InventoryModel?> getByPartNumber(
    String partNumber, {
    int? vehicleId,
  }) async {
    final rows = await _db.query(
      AppConstants.tableInventory,
      where: vehicleId == null
          ? 'part_number = ? AND vehicle_id IS NULL'
          : 'part_number = ? AND vehicle_id = ?',
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
      where:
          '(name LIKE ? OR brand LIKE ? OR part_number LIKE ? OR oem_number LIKE ? OR compatibility LIKE ?)$vehicleFilter',
      whereArgs:
          vehicleId == null ? [q, q, q, q, q] : [q, q, q, q, q, vehicleId],
      orderBy: 'name ASC',
    );
    return rows.map(InventoryModel.fromMap).toList();
  }
}
