import 'package:equatable/equatable.dart';

/// Represents a spare part in the inventory.
class InventoryModel extends Equatable {
  final int? id;
  final int? vehicleId;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleYear;
  final String name;
  final String? brand;
  final String? partNumber;
  final String? oemNumber;
  final String? category;
  final String? compatibility;
  final int quantity;
  final String? notes;
  final double? confidenceScore;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryModel({
    this.id,
    this.vehicleId,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleYear,
    required this.name,
    this.brand,
    this.partNumber,
    this.oemNumber,
    this.category,
    this.compatibility,
    this.quantity = 1,
    this.notes,
    this.confidenceScore,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vehicle_id': vehicleId,
      'vehicle_make': vehicleMake,
      'vehicle_model': vehicleModel,
      'vehicle_year': vehicleYear,
      'name': name,
      'brand': brand,
      'part_number': partNumber,
      'oem_number': oemNumber,
      'category': category,
      'compatibility': compatibility,
      'quantity': quantity,
      'notes': notes,
      'confidence_score': confidenceScore,
      'image_path': imagePath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory InventoryModel.fromMap(Map<String, dynamic> map) {
    return InventoryModel(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int?,
      vehicleMake: map['vehicle_make'] as String?,
      vehicleModel: map['vehicle_model'] as String?,
      vehicleYear: map['vehicle_year'] as String?,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      partNumber: map['part_number'] as String?,
      oemNumber: map['oem_number'] as String?,
      category: map['category'] as String?,
      compatibility: map['compatibility'] as String?,
      quantity: map['quantity'] as int? ?? 1,
      notes: map['notes'] as String?,
      confidenceScore: (map['confidence_score'] as num?)?.toDouble(),
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  InventoryModel copyWith({
    int? id,
    int? vehicleId,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleYear,
    String? name,
    String? brand,
    String? partNumber,
    String? oemNumber,
    String? category,
    String? compatibility,
    int? quantity,
    String? notes,
    double? confidenceScore,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      partNumber: partNumber ?? this.partNumber,
      oemNumber: oemNumber ?? this.oemNumber,
      category: category ?? this.category,
      compatibility: compatibility ?? this.compatibility,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, vehicleId, vehicleMake, vehicleModel, vehicleYear, name, brand,
        partNumber, oemNumber, category, compatibility, quantity, notes,
        confidenceScore, imagePath, createdAt, updatedAt,
      ];
}
