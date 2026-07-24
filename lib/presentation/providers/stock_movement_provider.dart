import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/stock_movement_model.dart';
import '../../data/repositories/stock_movement_repository.dart';

final stockMovementRepositoryProvider = Provider<StockMovementRepository>(
  (ref) => StockMovementRepository(),
);

final itemMovementsProvider =
    FutureProvider.autoDispose.family<List<StockMovementModel>, int>((ref, inventoryId) {
  return ref.read(stockMovementRepositoryProvider).getForItem(inventoryId);
});
