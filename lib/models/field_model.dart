/// Field model representing a farmer's agricultural field.
/// Maps to `fields/{fieldId}` in Firestore.
class FieldModel {
  final String id;
  final String ownerId;
  final String name;
  final double area; // in acres
  final double? latitude;
  final double? longitude;
  final String soilType;
  final DateTime createdAt;

  // Computed / UI-only
  final String? healthStatus; // 'good', 'moderate', 'poor'
  final int activeCrops;
  final int pendingActions;

  const FieldModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.area,
    this.latitude,
    this.longitude,
    required this.soilType,
    required this.createdAt,
    this.healthStatus,
    this.activeCrops = 0,
    this.pendingActions = 0,
  });

  factory FieldModel.fromMap(Map<String, dynamic> map, String id) {
    return FieldModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      area: (map['area'] ?? 0).toDouble(),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      soilType: map['soilType'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      healthStatus: map['healthStatus'],
      activeCrops: map['activeCrops'] ?? 0,
      pendingActions: map['pendingActions'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'soilType': soilType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  FieldModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    double? area,
    double? latitude,
    double? longitude,
    String? soilType,
    DateTime? createdAt,
    String? healthStatus,
    int? activeCrops,
    int? pendingActions,
  }) {
    return FieldModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      area: area ?? this.area,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      soilType: soilType ?? this.soilType,
      createdAt: createdAt ?? this.createdAt,
      healthStatus: healthStatus ?? this.healthStatus,
      activeCrops: activeCrops ?? this.activeCrops,
      pendingActions: pendingActions ?? this.pendingActions,
    );
  }

  String get locationString {
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
    }
    return 'Not set';
  }

  @override
  String toString() => 'FieldModel(id: $id, name: $name, area: $area acres)';
}
