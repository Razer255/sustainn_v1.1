/// Activity model representing an action performed on a crop.
/// Maps to `activities/{activityId}` in Firestore.
class ActivityModel {
  final String id;
  final String cropId;
  final ActivityType type;
  final DateTime date;
  final String notes;
  final double? cost; // in local currency
  final double? quantity; // e.g. liters of water, kg of fertilizer
  final String? unit; // e.g. 'liters', 'kg', 'ml'
  final String createdBy;

  const ActivityModel({
    required this.id,
    required this.cropId,
    required this.type,
    required this.date,
    required this.notes,
    this.cost,
    this.quantity,
    this.unit,
    required this.createdBy,
  });

  factory ActivityModel.fromMap(Map<String, dynamic> map, String id) {
    return ActivityModel(
      id: id,
      cropId: map['cropId'] ?? '',
      type: ActivityType.fromString(map['type'] ?? 'other'),
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      notes: map['notes'] ?? '',
      cost: map['cost']?.toDouble(),
      quantity: map['quantity']?.toDouble(),
      unit: map['unit'],
      createdBy: map['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cropId': cropId,
      'type': type.value,
      'date': date.toIso8601String(),
      'notes': notes,
      'cost': cost,
      'quantity': quantity,
      'unit': unit,
      'createdBy': createdBy,
    };
  }

  ActivityModel copyWith({
    String? id,
    String? cropId,
    ActivityType? type,
    DateTime? date,
    String? notes,
    double? cost,
    double? quantity,
    String? unit,
    String? createdBy,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      type: type ?? this.type,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      cost: cost ?? this.cost,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  String toString() =>
      'ActivityModel(id: $id, type: ${type.value}, date: $date)';
}

/// Types of farming activities.
enum ActivityType {
  irrigation('irrigation', '💧', 'Irrigation'),
  fertilizer('fertilizer', '🌱', 'Fertilizer'),
  pesticide('pesticide', '🛡️', 'Pesticide'),
  harvest('harvest', '🌾', 'Harvest'),
  sowing('sowing', '🌿', 'Sowing'),
  weeding('weeding', '🪴', 'Weeding'),
  soilTesting('soil_testing', '🔬', 'Soil Testing'),
  other('other', '📋', 'Other');

  const ActivityType(this.value, this.emoji, this.label);
  final String value;
  final String emoji;
  final String label;

  static ActivityType fromString(String value) {
    return ActivityType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => ActivityType.other,
    );
  }
}
