import '../../core/constants/app_constants.dart';
import '../datasources/local/database_helper.dart';
import '../models/vehicle_model.dart';

/// Data access layer for vehicles.
class VehicleRepository {
  final DatabaseHelper _db;

  VehicleRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  /// Inserts a new vehicle. Returns the row id.
  Future<int> insert(VehicleModel vehicle) async {
    final now = DateTime.now();
    final row = vehicle
        .copyWith(createdAt: now, updatedAt: now)
        .toMap();
    return _db.insert(AppConstants.tableVehicles, row);
  }

  /// Updates an existing vehicle. Returns the number of rows changed.
  Future<int> update(VehicleModel vehicle) async {
    final row = vehicle.copyWith(updatedAt: DateTime.now()).toMap();
    return _db.update(
      AppConstants.tableVehicles,
      row,
      'id = ?',
      [vehicle.id],
    );
  }

  /// Deletes a vehicle by id.
  Future<int> delete(int id) async {
    return _db.delete(AppConstants.tableVehicles, 'id = ?', [id]);
  }

  /// Fetches all vehicles, newest first.
  Future<List<VehicleModel>> getAll() async {
    final rows = await _db.query(
      AppConstants.tableVehicles,
      orderBy: 'created_at DESC',
    );
    return rows.map(VehicleModel.fromMap).toList();
  }

  /// Fetches a single vehicle by id.
  Future<VehicleModel?> getById(int id) async {
    final rows = await _db.query(
      AppConstants.tableVehicles,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return VehicleModel.fromMap(rows.first);
  }

  /// Full-text search across registration, brand, model, vin.
  Future<List<VehicleModel>> search(String query) async {
    final q = '%$query%';
    final rows = await _db.query(
      AppConstants.tableVehicles,
      where: 'registration LIKE ? OR brand LIKE ? OR model LIKE ? OR vin LIKE ?',
      whereArgs: [q, q, q, q],
      orderBy: 'created_at DESC',
    );
    return rows.map(VehicleModel.fromMap).toList();
  }
}
