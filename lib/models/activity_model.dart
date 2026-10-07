import 'activity_taxonomy.dart';

/// Activity model representing an action performed on a crop.
/// Maps to `activities/{activityId}` in Firestore.
class ActivityModel {
  final String id;
  final String cropId;
  final ActivityCategory category;
  final String? subtypeCode; // sub-activity code, e.g. 'NU_BASAL'
  final DateTime date;
  final double? areaCovered;
  final String? areaUnit; // e.g. 'acre', 'hectare', 'bigha'
  final String notes;
  final double? cost; // in local currency
  final double? quantity; // e.g. liters of water, kg of fertilizer
  final String? unit; // e.g. 'liters', 'kg', 'ml'
  final String createdBy;

  /// Category-specific fields (spec §5), keyed by [ActivityFieldDef.key],
  /// plus the bespoke keys 'productLines' (NUTRIENT), 'weedSpecies' (WEED)
  /// and 'pestsDiseases' (PLANT_PROTECT).
  final Map<String, dynamic> attributes;

  const ActivityModel({
    required this.id,
    required this.cropId,
    required this.category,
    this.subtypeCode,
    required this.date,
    this.areaCovered,
    this.areaUnit,
    required this.notes,
    this.cost,
    this.quantity,
    this.unit,
    required this.createdBy,
    this.attributes = const {},
  });

  /// The chosen sub-activity, if any — looked up from the taxonomy master list.
  ActivitySubtype? get subtype => subtypeByCode(subtypeCode);

  /// Best available label for display: sub-activity if known, else category.
  String get displayLabel => subtype?.label ?? category.label;

  factory ActivityModel.fromMap(Map<String, dynamic> map, String id) {
    return ActivityModel(
      id: id,
      cropId: map['cropId'] ?? '',
      category: ActivityCategory.fromCode(map['type'] ?? 'OTHER'),
      subtypeCode: map['subtype'],
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      areaCovered: map['areaCovered']?.toDouble(),
      areaUnit: map['areaUnit'],
      notes: map['notes'] ?? '',
      cost: map['cost']?.toDouble(),
      quantity: map['quantity']?.toDouble(),
      unit: map['unit'],
      createdBy: map['createdBy'] ?? '',
      attributes: map['attributes'] != null
          ? Map<String, dynamic>.from(map['attributes'])
          : const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cropId': cropId,
      'type': category.code,
      'subtype': subtypeCode,
      'date': date.toIso8601String(),
      'areaCovered': areaCovered,
      'areaUnit': areaUnit,
      'notes': notes,
      'cost': cost,
      'quantity': quantity,
      'unit': unit,
      'createdBy': createdBy,
      'attributes': attributes,
    };
  }

  ActivityModel copyWith({
    String? id,
    String? cropId,
    ActivityCategory? category,
    String? subtypeCode,
    DateTime? date,
    double? areaCovered,
    String? areaUnit,
    String? notes,
    double? cost,
    double? quantity,
    String? unit,
    String? createdBy,
    Map<String, dynamic>? attributes,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      category: category ?? this.category,
      subtypeCode: subtypeCode ?? this.subtypeCode,
      date: date ?? this.date,
      areaCovered: areaCovered ?? this.areaCovered,
      areaUnit: areaUnit ?? this.areaUnit,
      notes: notes ?? this.notes,
      cost: cost ?? this.cost,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      createdBy: createdBy ?? this.createdBy,
      attributes: attributes ?? this.attributes,
    );
  }

  @override
  String toString() =>
      'ActivityModel(id: $id, category: ${category.code}, subtype: $subtypeCode, date: $date)';
}
