import '../../core/constants/app_constants.dart';
import '../datasources/local/database_helper.dart';
import '../models/stock_movement_model.dart';

class StockMovementRepository {
  final DatabaseHelper _db;
  StockMovementRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  Future<int> insert(StockMovementModel movement) async {
    final row = movement.copyWith(createdAt: movement.createdAt).toMap();
    return _db.insert(AppConstants.tableStockMovements, row);
  }

  Future<List<StockMovementModel>> getForItem(int inventoryId, {int limit = 50}) async {
    final rows = await _db.query(
      AppConstants.tableStockMovements,
      where: 'inventory_id = ?',
      whereArgs: [inventoryId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(StockMovementModel.fromMap).toList();
  }

  Future<List<StockMovementModel>> getRecent({int limit = 30}) async {
    final rows = await _db.query(
      AppConstants.tableStockMovements,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(StockMovementModel.fromMap).toList();
  }
}

extension _CopyWith on StockMovementModel {
  StockMovementModel copyWith({DateTime? createdAt}) => StockMovementModel(
        id: id,
        inventoryId: inventoryId,
        type: type,
        quantityChange: quantityChange,
        jobId: jobId,
        notes: notes,
        createdAt: createdAt ?? this.createdAt,
      );
}
