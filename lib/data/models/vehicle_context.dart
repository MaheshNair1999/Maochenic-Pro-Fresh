import 'vehicle_model.dart';

/// Persistent context for the vehicle currently being worked on.
class VehicleContext {
  final int? vehicleId;
  final String? make;
  final String? model;
  final String? year;
  final String? vin;
  final String? registration;
  final String? fuel;
  final String? engine;
  final String? engineCode;
  final String? horsepower;
  final String? colour;
  final String? category;

  const VehicleContext({
    this.vehicleId,
    this.make,
    this.model,
    this.year,
    this.vin,
    this.registration,
    this.fuel,
    this.engine,
    this.engineCode,
    this.horsepower,
    this.colour,
    this.category,
  });

  factory VehicleContext.fromVehicle(VehicleModel vehicle) {
    return VehicleContext(
      vehicleId: vehicle.id,
      make: vehicle.brand,
      model: vehicle.model,
      year: vehicle.year,
      vin: vehicle.vin,
      registration: vehicle.registration,
      fuel: vehicle.fuelType,
      engine: vehicle.engineSize,
      engineCode: vehicle.extraFields['engineCode'],
      horsepower: vehicle.extraFields['horsepower'],
      colour: vehicle.color,
      category: vehicle.extraFields['vehicleCategory'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'make': make ?? '',
      'model': model ?? '',
      'year': year ?? '',
      'vin': vin ?? '',
      'registration': registration ?? '',
      'fuel': fuel ?? '',
      'engine': engine ?? '',
      'engineCode': engineCode ?? '',
      'horsepower': horsepower ?? '',
      'colour': colour ?? '',
      'category': category ?? '',
    };
  }

  String get displayName {
    final parts = [make, model].where((p) => p != null && p.trim().isNotEmpty);
    final name = parts.map((p) => p!.trim()).join(' ');
    if (name.isEmpty) return registration ?? 'Selected vehicle';
    return year == null || year!.trim().isEmpty ? name : '$name ($year)';
  }
}
