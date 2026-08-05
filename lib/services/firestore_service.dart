import 'package:flutter/foundation.dart';

/// Firestore service providing CRUD operations for all collections.
/// Currently uses mock data. Replace implementations with actual
/// Firestore calls once Firebase is configured.
class FirestoreService {
  // ─── Users ──────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUser(String userId) async {
    debugPrint('[FirestoreService] getUser($userId)');
    // TODO: return Firestore document snapshot
    return null;
  }

  Future<void> createUser(String userId, Map<String, dynamic> data) async {
    debugPrint('[FirestoreService] createUser($userId)');
    // TODO: Firestore set
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    debugPrint('[FirestoreService] updateUser($userId)');
    // TODO: Firestore update
  }

  // ─── Fields ─────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getFieldsStream(String ownerId) {
    debugPrint('[FirestoreService] getFieldsStream($ownerId)');
    // TODO: return Firestore collection stream filtered by ownerId
    return const Stream.empty();
  }

  Future<String> addField(Map<String, dynamic> data) async {
    debugPrint('[FirestoreService] addField(${data['name']})');
    // TODO: Firestore add, return generated ID
    return 'generated_field_id';
  }

  Future<void> updateField(String fieldId, Map<String, dynamic> data) async {
    debugPrint('[FirestoreService] updateField($fieldId)');
    // TODO: Firestore update
  }

  Future<void> deleteField(String fieldId) async {
    debugPrint('[FirestoreService] deleteField($fieldId)');
    // TODO: Firestore delete (consider cascading deletes)
  }

  // ─── Crops ──────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getCropsStream(String fieldId) {
    debugPrint('[FirestoreService] getCropsStream($fieldId)');
    return const Stream.empty();
  }

  Future<String> addCrop(Map<String, dynamic> data) async {
    debugPrint('[FirestoreService] addCrop(${data['cropName']})');
    return 'generated_crop_id';
  }

  Future<void> updateCrop(String cropId, Map<String, dynamic> data) async {
    debugPrint('[FirestoreService] updateCrop($cropId)');
  }

  // ─── Activities ─────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getActivitiesStream(String cropId) {
    debugPrint('[FirestoreService] getActivitiesStream($cropId)');
    return const Stream.empty();
  }

  Future<String> addActivity(Map<String, dynamic> data) async {
    debugPrint('[FirestoreService] addActivity(${data['type']})');
    return 'generated_activity_id';
  }

  // ─── Action Points ─────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getActionPointsStream({
    required String scope,
    required String refId,
  }) {
    debugPrint('[FirestoreService] getActionPointsStream($scope, $refId)');
    return const Stream.empty();
  }

  Future<void> resolveActionPoint(String actionPointId) async {
    debugPrint('[FirestoreService] resolveActionPoint($actionPointId)');
  }

  // ─── Financials ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> getFinancials(String cropId) async {
    debugPrint('[FirestoreService] getFinancials($cropId)');
    return null;
  }

  Future<void> updateFinancials(
      String cropId, Map<String, dynamic> data) async {
    debugPrint('[FirestoreService] updateFinancials($cropId)');
  }
}
