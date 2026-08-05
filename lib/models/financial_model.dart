/// Financial model tracking input costs and revenue for a crop.
/// Maps to `financials/{id}` in Firestore.
class FinancialModel {
  final String id;
  final String cropId;
  final double inputCost;
  final double expectedRevenue;
  final double actualRevenue;
  final DateTime updatedAt;

  const FinancialModel({
    required this.id,
    required this.cropId,
    required this.inputCost,
    required this.expectedRevenue,
    required this.actualRevenue,
    required this.updatedAt,
  });

  factory FinancialModel.fromMap(Map<String, dynamic> map, String id) {
    return FinancialModel(
      id: id,
      cropId: map['cropId'] ?? '',
      inputCost: (map['inputCost'] ?? 0).toDouble(),
      expectedRevenue: (map['expectedRevenue'] ?? 0).toDouble(),
      actualRevenue: (map['actualRevenue'] ?? 0).toDouble(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cropId': cropId,
      'inputCost': inputCost,
      'expectedRevenue': expectedRevenue,
      'actualRevenue': actualRevenue,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  FinancialModel copyWith({
    String? id,
    String? cropId,
    double? inputCost,
    double? expectedRevenue,
    double? actualRevenue,
    DateTime? updatedAt,
  }) {
    return FinancialModel(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      inputCost: inputCost ?? this.inputCost,
      expectedRevenue: expectedRevenue ?? this.expectedRevenue,
      actualRevenue: actualRevenue ?? this.actualRevenue,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Expected profit based on expected revenue minus input cost.
  double get expectedProfit => expectedRevenue - inputCost;

  /// Actual profit based on actual revenue minus input cost.
  double get actualProfit => actualRevenue - inputCost;

  /// Return on investment percentage.
  double get roi {
    if (inputCost == 0) return 0;
    return (actualProfit / inputCost) * 100;
  }

  /// Whether the crop is currently profitable.
  bool get isProfitable => actualProfit > 0;

  @override
  String toString() =>
      'FinancialModel(id: $id, cropId: $cropId, profit: $actualProfit)';
}
