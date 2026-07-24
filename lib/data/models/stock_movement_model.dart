class StockMovementModel {
  final int? id;
  final int inventoryId;
  final String type; // 'received', 'used_in_job', 'returned_from_job', 'manual_in', 'manual_out'
  final int quantityChange; // positive = stock added, negative = stock removed
  final int? jobId;
  final String? notes;
  final DateTime createdAt;

  const StockMovementModel({
    this.id,
    required this.inventoryId,
    required this.type,
    required this.quantityChange,
    this.jobId,
    this.notes,
    required this.createdAt,
  });

  String get typeLabel => switch (type) {
        'received' => 'Received / Παραλήφθηκε',
        'used_in_job' => 'Used in Job / Χρησιμοποιήθηκε',
        'returned_from_job' => 'Returned / Επιστράφηκε',
        'manual_in' => 'Manual Add / Χειροκίνητη Προσθήκη',
        'manual_out' => 'Manual Remove / Χειροκίνητη Αφαίρεση',
        _ => type,
      };

  bool get isPositive => quantityChange > 0;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'inventory_id': inventoryId,
        'type': type,
        'quantity_change': quantityChange,
        'job_id': jobId,
        'notes': notes,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory StockMovementModel.fromMap(Map<String, dynamic> map) =>
      StockMovementModel(
        id: map['id'] as int?,
        inventoryId: map['inventory_id'] as int,
        type: map['type'] as String,
        quantityChange: map['quantity_change'] as int,
        jobId: map['job_id'] as int?,
        notes: map['notes'] as String?,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
