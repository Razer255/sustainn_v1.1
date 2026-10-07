/// A single boundary corner marked on the field map (§ Add Field).
/// Kept plain (not `LatLng`) so this model has no dependency on the map
/// plugin — the boundary-marking screen converts at the edges.
class FieldBoundaryPoint {
  final double lat;
  final double lng;

  const FieldBoundaryPoint({required this.lat, required this.lng});

  factory FieldBoundaryPoint.fromMap(Map<String, dynamic> map) {
    return FieldBoundaryPoint(
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {'lat': lat, 'lng': lng};
}

/// Field model representing a farmer's agricultural field.
/// Maps to `fields/{fieldId}` in Firestore.
class FieldModel {
  final String id;
  final String ownerId;
  final String name;
  final double area; // in acres
  final double? latitude;
  final double? longitude;
  final List<FieldBoundaryPoint> boundaryPoints;
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
    this.boundaryPoints = const [],
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
      boundaryPoints: map['boundaryPoints'] != null
          ? (map['boundaryPoints'] as List)
              .map((p) => FieldBoundaryPoint.fromMap(Map<String, dynamic>.from(p)))
              .toList()
          : const [],
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
      'boundaryPoints': boundaryPoints.map((p) => p.toMap()).toList(),
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
    List<FieldBoundaryPoint>? boundaryPoints,
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
      boundaryPoints: boundaryPoints ?? this.boundaryPoints,
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
