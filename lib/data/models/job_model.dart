import 'package:equatable/equatable.dart';

/// Job status values.
enum JobStatus {
  open,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case JobStatus.open:
        return 'Open';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  static JobStatus fromString(String value) {
    return JobStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => JobStatus.open,
    );
  }
}

/// A part line-item inside a job sheet.
class JobPartModel extends Equatable {
  final int? id;
  final int jobId;
  final int? inventoryId;
  final String name;
  final String? partNumber;
  final String? brand;
  final int quantity;
  final String? notes;

  const JobPartModel({
    this.id,
    required this.jobId,
    this.inventoryId,
    required this.name,
    this.partNumber,
    this.brand,
    this.quantity = 1,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'job_id': jobId,
      'inventory_id': inventoryId,
      'name': name,
      'part_number': partNumber,
      'brand': brand,
      'quantity': quantity,
      'notes': notes,
    };
  }

  factory JobPartModel.fromMap(Map<String, dynamic> map) {
    return JobPartModel(
      id: map['id'] as int?,
      jobId: map['job_id'] as int,
      inventoryId: map['inventory_id'] as int?,
      name: map['name'] as String,
      partNumber: map['part_number'] as String?,
      brand: map['brand'] as String?,
      quantity: map['quantity'] as int? ?? 1,
      notes: map['notes'] as String?,
    );
  }

  JobPartModel copyWith({
    int? id,
    int? jobId,
    int? inventoryId,
    String? name,
    String? partNumber,
    String? brand,
    int? quantity,
    String? notes,
  }) {
    return JobPartModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      inventoryId: inventoryId ?? this.inventoryId,
      name: name ?? this.name,
      partNumber: partNumber ?? this.partNumber,
      brand: brand ?? this.brand,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props =>
      [id, jobId, inventoryId, name, partNumber, brand, quantity, notes];
}

/// Represents a job sheet attached to a vehicle.
class JobModel extends Equatable {
  final int? id;
  final int vehicleId;
  final String? customer;
  final String? description;
  final JobStatus status;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Loaded separately (not stored in this table)
  final List<JobPartModel> parts;

  const JobModel({
    this.id,
    required this.vehicleId,
    this.customer,
    this.description,
    this.status = JobStatus.open,
    required this.date,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.parts = const [],
  });

  int get totalPartsCount =>
      parts.fold(0, (sum, p) => sum + p.quantity);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vehicle_id': vehicleId,
      'customer': customer,
      'description': description,
      'status': status.name,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory JobModel.fromMap(
    Map<String, dynamic> map, {
    List<JobPartModel> parts = const [],
  }) {
    return JobModel(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int,
      customer: map['customer'] as String?,
      description: map['description'] as String?,
      status: JobStatus.fromString(map['status'] as String? ?? 'open'),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      parts: parts,
    );
  }

  JobModel copyWith({
    int? id,
    int? vehicleId,
    String? customer,
    String? description,
    JobStatus? status,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<JobPartModel>? parts,
  }) {
    return JobModel(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      customer: customer ?? this.customer,
      description: description ?? this.description,
      status: status ?? this.status,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parts: parts ?? this.parts,
    );
  }

  @override
  List<Object?> get props => [
        id, vehicleId, customer, description,
        status, date, notes, createdAt, updatedAt, parts,
      ];
}
