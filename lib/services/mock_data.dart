import '../models/user_model.dart';
import '../models/field_model.dart';
import '../models/crop_model.dart';
import '../models/activity_model.dart';
import '../models/action_point_model.dart';
import '../models/financial_model.dart';

/// Provides realistic mock data for all screens.
/// Replace with Firestore calls once Firebase is configured.
class MockData {
  MockData._();

  static final UserModel currentUser = UserModel(
    id: 'user_001',
    phone: '+91 98765 43210',
    name: 'Rajesh Kumar',
    language: 'en',
    region: 'Pune, Maharashtra',
    createdAt: DateTime(2025, 3, 15),
  );

  static final List<FieldModel> fields = [
    FieldModel(
      id: 'field_001',
      ownerId: 'user_001',
      name: 'North Field',
      area: 2.5,
      latitude: 18.5204,
      longitude: 73.8567,
      soilType: 'Black Cotton',
      createdAt: DateTime(2025, 3, 20),
      healthStatus: 'good',
      activeCrops: 2,
      pendingActions: 3,
    ),
    FieldModel(
      id: 'field_002',
      ownerId: 'user_001',
      name: 'Riverside Plot',
      area: 1.8,
      latitude: 18.5250,
      longitude: 73.8600,
      soilType: 'Alluvial',
      createdAt: DateTime(2025, 4, 10),
      healthStatus: 'moderate',
      activeCrops: 1,
      pendingActions: 5,
    ),
    FieldModel(
      id: 'field_003',
      ownerId: 'user_001',
      name: 'Hill Terrace',
      area: 3.2,
      latitude: 18.5300,
      longitude: 73.8650,
      soilType: 'Red Laterite',
      createdAt: DateTime(2025, 5, 1),
      healthStatus: 'poor',
      activeCrops: 1,
      pendingActions: 7,
    ),
  ];

  static final List<CropModel> crops = [
    CropModel(
      id: 'crop_001',
      fieldId: 'field_001',
      season: 'Kharif 2026',
      cropName: 'Rice (Paddy)',
      variety: 'Basmati 1121',
      sownDate: DateTime(2026, 6, 15),
      expectedHarvestDate: DateTime(2026, 10, 20),
      status: CropStatus.active,
      healthStatus: 'good',
      activityCount: 12,
    ),
    CropModel(
      id: 'crop_002',
      fieldId: 'field_001',
      season: 'Kharif 2026',
      cropName: 'Cotton',
      variety: 'Bt Cotton (Bollgard II)',
      sownDate: DateTime(2026, 6, 1),
      expectedHarvestDate: DateTime(2026, 11, 30),
      status: CropStatus.active,
      healthStatus: 'moderate',
      activityCount: 8,
    ),
    CropModel(
      id: 'crop_003',
      fieldId: 'field_002',
      season: 'Kharif 2026',
      cropName: 'Soybean',
      variety: 'JS-9560',
      sownDate: DateTime(2026, 6, 20),
      expectedHarvestDate: DateTime(2026, 10, 15),
      status: CropStatus.active,
      healthStatus: 'good',
      activityCount: 6,
    ),
    CropModel(
      id: 'crop_004',
      fieldId: 'field_003',
      season: 'Kharif 2026',
      cropName: 'Sugarcane',
      variety: 'CoM 0265',
      sownDate: DateTime(2026, 2, 10),
      expectedHarvestDate: DateTime(2027, 1, 15),
      status: CropStatus.active,
      healthStatus: 'poor',
      activityCount: 15,
    ),
  ];

  static final List<ActivityModel> activities = [
    ActivityModel(
      id: 'act_001',
      cropId: 'crop_001',
      type: ActivityType.sowing,
      date: DateTime(2026, 6, 15),
      notes: 'Transplanted nursery seedlings to main field',
      cost: 3500,
      quantity: 25,
      unit: 'kg',
      createdBy: 'user_001',
    ),
    ActivityModel(
      id: 'act_002',
      cropId: 'crop_001',
      type: ActivityType.irrigation,
      date: DateTime(2026, 6, 22),
      notes: 'First irrigation after transplanting',
      cost: 500,
      quantity: 2000,
      unit: 'liters',
      createdBy: 'user_001',
    ),
    ActivityModel(
      id: 'act_003',
      cropId: 'crop_001',
      type: ActivityType.fertilizer,
      date: DateTime(2026, 7, 1),
      notes: 'Applied DAP fertilizer (first dose)',
      cost: 1800,
      quantity: 50,
      unit: 'kg',
      createdBy: 'user_001',
    ),
    ActivityModel(
      id: 'act_004',
      cropId: 'crop_001',
      type: ActivityType.pesticide,
      date: DateTime(2026, 7, 15),
      notes: 'Sprayed Chlorantraniliprole for stem borer prevention',
      cost: 1200,
      quantity: 500,
      unit: 'ml',
      createdBy: 'user_001',
    ),
    ActivityModel(
      id: 'act_005',
      cropId: 'crop_001',
      type: ActivityType.weeding,
      date: DateTime(2026, 7, 20),
      notes: 'Manual weeding by laborers',
      cost: 2500,
      createdBy: 'user_001',
    ),
    ActivityModel(
      id: 'act_006',
      cropId: 'crop_001',
      type: ActivityType.irrigation,
      date: DateTime(2026, 7, 28),
      notes: 'Second irrigation cycle',
      cost: 500,
      quantity: 2000,
      unit: 'liters',
      createdBy: 'user_001',
    ),
    ActivityModel(
      id: 'act_007',
      cropId: 'crop_002',
      type: ActivityType.sowing,
      date: DateTime(2026, 6, 1),
      notes: 'Direct seeding of Bt Cotton seeds',
      cost: 4500,
      quantity: 2,
      unit: 'packets',
      createdBy: 'user_001',
    ),
    ActivityModel(
      id: 'act_008',
      cropId: 'crop_002',
      type: ActivityType.fertilizer,
      date: DateTime(2026, 6, 25),
      notes: 'Applied Urea (first dose)',
      cost: 900,
      quantity: 30,
      unit: 'kg',
      createdBy: 'user_001',
    ),
  ];

  static final List<ActionPointModel> actionPoints = [
    ActionPointModel(
      id: 'ap_001',
      scope: ActionScope.crop,
      refId: 'crop_001',
      message: 'Apply second dose of Urea fertilizer — optimal window in 3 days',
      priority: ActionPriority.high,
      dueDate: DateTime.now().add(const Duration(days: 3)),
      category: 'fertilizer',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ActionPointModel(
      id: 'ap_002',
      scope: ActionScope.field,
      refId: 'field_002',
      message: 'Weather alert: Heavy rain expected in 2 days — delay pesticide spray',
      priority: ActionPriority.high,
      dueDate: DateTime.now().add(const Duration(days: 2)),
      category: 'weather',
      createdAt: DateTime.now(),
    ),
    ActionPointModel(
      id: 'ap_003',
      scope: ActionScope.crop,
      refId: 'crop_004',
      message: 'Sugarcane showing signs of red rot — inspect and treat immediately',
      priority: ActionPriority.high,
      dueDate: DateTime.now(),
      category: 'pest',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ActionPointModel(
      id: 'ap_004',
      scope: ActionScope.farmer,
      refId: 'user_001',
      message: 'Soil testing recommended for Hill Terrace field — last test 6 months ago',
      priority: ActionPriority.medium,
      dueDate: DateTime.now().add(const Duration(days: 7)),
      category: 'soil',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ActionPointModel(
      id: 'ap_005',
      scope: ActionScope.crop,
      refId: 'crop_002',
      message: 'Cotton bolls forming — schedule next irrigation within 5 days',
      priority: ActionPriority.medium,
      dueDate: DateTime.now().add(const Duration(days: 5)),
      category: 'irrigation',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ActionPointModel(
      id: 'ap_006',
      scope: ActionScope.field,
      refId: 'field_001',
      message: 'Consider intercropping with legumes for nitrogen fixation next season',
      priority: ActionPriority.low,
      dueDate: DateTime.now().add(const Duration(days: 30)),
      category: 'planning',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static final List<FinancialModel> financials = [
    FinancialModel(
      id: 'fin_001',
      cropId: 'crop_001',
      inputCost: 10000,
      expectedRevenue: 35000,
      actualRevenue: 0,
      updatedAt: DateTime.now(),
    ),
    FinancialModel(
      id: 'fin_002',
      cropId: 'crop_002',
      inputCost: 8200,
      expectedRevenue: 28000,
      actualRevenue: 0,
      updatedAt: DateTime.now(),
    ),
    FinancialModel(
      id: 'fin_003',
      cropId: 'crop_003',
      inputCost: 5500,
      expectedRevenue: 18000,
      actualRevenue: 0,
      updatedAt: DateTime.now(),
    ),
    FinancialModel(
      id: 'fin_004',
      cropId: 'crop_004',
      inputCost: 22000,
      expectedRevenue: 75000,
      actualRevenue: 0,
      updatedAt: DateTime.now(),
    ),
  ];

  // ─── Helper methods ────────────────────────────────────────

  static List<CropModel> getCropsForField(String fieldId) {
    return crops.where((c) => c.fieldId == fieldId).toList();
  }

  static List<ActivityModel> getActivitiesForCrop(String cropId) {
    final list = activities.where((a) => a.cropId == cropId).toList();
    list.sort((a, b) => b.date.compareTo(a.date)); // newest first
    return list;
  }

  static List<ActionPointModel> getActionPointsForScope(
      ActionScope scope, String refId) {
    return actionPoints
        .where((ap) => ap.scope == scope && ap.refId == refId && !ap.resolved)
        .toList()
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
  }

  static List<ActionPointModel> getAllUnresolvedActionPoints() {
    return actionPoints.where((ap) => !ap.resolved).toList()
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
  }

  static FinancialModel? getFinancialsForCrop(String cropId) {
    try {
      return financials.firstWhere((f) => f.cropId == cropId);
    } catch (_) {
      return null;
    }
  }

  static double getTotalInputCostForCrop(String cropId) {
    return getActivitiesForCrop(cropId)
        .fold(0.0, (sum, a) => sum + (a.cost ?? 0));
  }
}
