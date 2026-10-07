/// Crop model representing a specific crop planted in a field for a season.
/// Maps to `crops/{cropId}` in Firestore.
class CropModel {
  final String id;
  final String fieldId;
  final String season; // e.g. 'Kharif 2026', 'Rabi 2025-26'
  final String cropName;
  final String variety;
  final DateTime sownDate;
  final DateTime? expectedHarvestDate;
  final CropStatus status;
  final bool isIntercrop; // grown alongside another crop on the same land
  final double areaCovered; // acres

  // Computed / UI-only
  final String? healthStatus; // 'good', 'moderate', 'poor'
  final int activityCount;

  const CropModel({
    required this.id,
    required this.fieldId,
    required this.season,
    required this.cropName,
    required this.variety,
    required this.sownDate,
    this.expectedHarvestDate,
    required this.status,
    this.isIntercrop = false,
    this.areaCovered = 0,
    this.healthStatus,
    this.activityCount = 0,
  });

  factory CropModel.fromMap(Map<String, dynamic> map, String id) {
    return CropModel(
      id: id,
      fieldId: map['fieldId'] ?? '',
      season: map['season'] ?? '',
      cropName: map['cropName'] ?? '',
      variety: map['variety'] ?? '',
      sownDate: map['sownDate'] != null
          ? DateTime.parse(map['sownDate'])
          : DateTime.now(),
      expectedHarvestDate: map['expectedHarvestDate'] != null
          ? DateTime.parse(map['expectedHarvestDate'])
          : null,
      status: CropStatus.fromString(map['status'] ?? 'active'),
      isIntercrop: map['isIntercrop'] ?? false,
      areaCovered: (map['areaCovered'] ?? 0).toDouble(),
      healthStatus: map['healthStatus'],
      activityCount: map['activityCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fieldId': fieldId,
      'season': season,
      'cropName': cropName,
      'variety': variety,
      'sownDate': sownDate.toIso8601String(),
      'expectedHarvestDate': expectedHarvestDate?.toIso8601String(),
      'status': status.value,
      'isIntercrop': isIntercrop,
      'areaCovered': areaCovered,
    };
  }

  CropModel copyWith({
    String? id,
    String? fieldId,
    String? season,
    String? cropName,
    String? variety,
    DateTime? sownDate,
    DateTime? expectedHarvestDate,
    CropStatus? status,
    bool? isIntercrop,
    double? areaCovered,
    String? healthStatus,
    int? activityCount,
  }) {
    return CropModel(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      season: season ?? this.season,
      cropName: cropName ?? this.cropName,
      variety: variety ?? this.variety,
      sownDate: sownDate ?? this.sownDate,
      expectedHarvestDate: expectedHarvestDate ?? this.expectedHarvestDate,
      status: status ?? this.status,
      isIntercrop: isIntercrop ?? this.isIntercrop,
      areaCovered: areaCovered ?? this.areaCovered,
      healthStatus: healthStatus ?? this.healthStatus,
      activityCount: activityCount ?? this.activityCount,
    );
  }

  int get daysToHarvest {
    if (expectedHarvestDate == null) return -1;
    return expectedHarvestDate!.difference(DateTime.now()).inDays;
  }

  int get daysSinceSowing {
    return DateTime.now().difference(sownDate).inDays;
  }

  @override
  String toString() =>
      'CropModel(id: $id, crop: $cropName, variety: $variety, season: $season)';
}

/// Crop lifecycle status.
enum CropStatus {
  active('active'),
  harvested('harvested'),
  failed('failed');

  const CropStatus(this.value);
  final String value;

  static CropStatus fromString(String value) {
    return CropStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => CropStatus.active,
    );
  }
}
