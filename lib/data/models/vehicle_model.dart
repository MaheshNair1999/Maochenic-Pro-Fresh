import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Represents a vehicle scanned from a registration document.
class VehicleModel extends Equatable {
  final int? id;
  final String registration;
  final String? vin;
  final String? brand;
  final String? model;
  final String? fuelType;
  final String? engineSize;
  final String? year;
  final String? owner;
  final String? color;
  final Map<String, String> extraFields; // Any additional OCR fields
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehicleModel({
    this.id,
    required this.registration,
    this.vin,
    this.brand,
    this.model,
    this.fuelType,
    this.engineSize,
    this.year,
    this.owner,
    this.color,
    this.extraFields = const {},
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Human-readable display title.
  String get displayTitle {
    final parts = [brand, model].whereType<String>().join(' ');
    return parts.isNotEmpty ? parts : registration;
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'registration': registration,
      'vin': vin,
      'brand': brand,
      'model': model,
      'fuel_type': fuelType,
      'engine_size': engineSize,
      'year': year,
      'owner': owner,
      'color': color,
      'extra_fields': jsonEncode(extraFields),
      'image_path': imagePath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory VehicleModel.fromMap(Map<String, dynamic> map) {
    Map<String, String> extras = {};
    if (map['extra_fields'] != null) {
      final decoded = jsonDecode(map['extra_fields'] as String);
      if (decoded is Map) {
        extras = decoded.cast<String, String>();
      }
    }

    return VehicleModel(
      id: map['id'] as int?,
      registration: map['registration'] as String,
      vin: map['vin'] as String?,
      brand: map['brand'] as String?,
      model: map['model'] as String?,
      fuelType: map['fuel_type'] as String?,
      engineSize: map['engine_size'] as String?,
      year: map['year'] as String?,
      owner: map['owner'] as String?,
      color: map['color'] as String?,
      extraFields: extras,
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  VehicleModel copyWith({
    int? id,
    String? registration,
    String? vin,
    String? brand,
    String? model,
    String? fuelType,
    String? engineSize,
    String? year,
    String? owner,
    String? color,
    Map<String, String>? extraFields,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      registration: registration ?? this.registration,
      vin: vin ?? this.vin,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      fuelType: fuelType ?? this.fuelType,
      engineSize: engineSize ?? this.engineSize,
      year: year ?? this.year,
      owner: owner ?? this.owner,
      color: color ?? this.color,
      extraFields: extraFields ?? this.extraFields,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, registration, vin, brand, model,
        fuelType, engineSize, year, owner, color,
        extraFields, imagePath, createdAt, updatedAt,
      ];
}
