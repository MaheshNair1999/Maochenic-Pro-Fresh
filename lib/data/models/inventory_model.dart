import 'dart:convert';
import 'package:equatable/equatable.dart';

class InventoryModel extends Equatable {
  final int? id;
  final int? vehicleId;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleYear;
  final String name;
  final String? nameGr;
  final String? brand;
  final String? partNumber;
  final String? oemNumber;
  final String? category;
  final String? compatibility;
  final String? description;
  final String? descriptionGr;
  final int quantity;
  final int minQuantity;
  final List<int> compatibleVehicleIds;
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
    this.nameGr,
    this.brand,
    this.partNumber,
    this.oemNumber,
    this.category,
    this.compatibility,
    this.description,
    this.descriptionGr,
    this.quantity = 1,
    this.minQuantity = 0,
    this.compatibleVehicleIds = const [],
    this.notes,
    this.confidenceScore,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => minQuantity > 0 && quantity <= minQuantity;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vehicle_id': vehicleId,
      'vehicle_make': vehicleMake,
      'vehicle_model': vehicleModel,
      'vehicle_year': vehicleYear,
      'name': name,
      'name_gr': nameGr,
      'brand': brand,
      'part_number': partNumber,
      'oem_number': oemNumber,
      'category': category,
      'compatibility': compatibility,
      'description': description,
      'description_gr': descriptionGr,
      'quantity': quantity,
      'min_quantity': minQuantity,
      'compatible_vehicle_ids': jsonEncode(compatibleVehicleIds),
      'notes': notes,
      'confidence_score': confidenceScore,
      'image_path': imagePath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory InventoryModel.fromMap(Map<String, dynamic> map) {
    List<int> vehicleIds = [];
    if (map['compatible_vehicle_ids'] != null) {
      try {
        final decoded = jsonDecode(map['compatible_vehicle_ids'] as String);
        if (decoded is List) vehicleIds = decoded.cast<int>();
      } catch (_) {}
    }

    return InventoryModel(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int?,
      vehicleMake: map['vehicle_make'] as String?,
      vehicleModel: map['vehicle_model'] as String?,
      vehicleYear: map['vehicle_year'] as String?,
      name: map['name'] as String,
      nameGr: map['name_gr'] as String?,
      brand: map['brand'] as String?,
      partNumber: map['part_number'] as String?,
      oemNumber: map['oem_number'] as String?,
      category: map['category'] as String?,
      compatibility: map['compatibility'] as String?,
      description: map['description'] as String?,
      descriptionGr: map['description_gr'] as String?,
      quantity: map['quantity'] as int? ?? 1,
      minQuantity: map['min_quantity'] as int? ?? 0,
      compatibleVehicleIds: vehicleIds,
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
    String? nameGr,
    String? brand,
    String? partNumber,
    String? oemNumber,
    String? category,
    String? compatibility,
    String? description,
    String? descriptionGr,
    int? quantity,
    int? minQuantity,
    List<int>? compatibleVehicleIds,
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
      nameGr: nameGr ?? this.nameGr,
      brand: brand ?? this.brand,
      partNumber: partNumber ?? this.partNumber,
      oemNumber: oemNumber ?? this.oemNumber,
      category: category ?? this.category,
      compatibility: compatibility ?? this.compatibility,
      description: description ?? this.description,
      descriptionGr: descriptionGr ?? this.descriptionGr,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      compatibleVehicleIds: compatibleVehicleIds ?? this.compatibleVehicleIds,
      notes: notes ?? this.notes,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, vehicleId, vehicleMake, vehicleModel, vehicleYear, name, nameGr,
        brand, partNumber, oemNumber, category, compatibility, description,
        descriptionGr, quantity, minQuantity, compatibleVehicleIds, notes,
        confidenceScore, imagePath, createdAt, updatedAt,
      ];
}
