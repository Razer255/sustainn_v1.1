import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'mock_data.dart';
import '../models/user_model.dart';
import '../models/field_model.dart';
import '../models/crop_model.dart';
import '../models/activity_model.dart';
import '../models/action_point_model.dart';
import '../models/financial_model.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _userProfileExists = false; 
  String? _userId;
  String? _phoneNumber;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get userProfileExists => _userProfileExists;
  String? get userId => _userId;
  String? get phoneNumber => _phoneNumber;

  AuthService() {
    // Optionally check if user is already authenticated via secure storage / Hive.
    // For now, we leave it as not authenticated until login.
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _apiService.login(identifier, password);

    if (result != null) {
      _isAuthenticated = true;
      _userId = result['user']['id'];
      _phoneNumber = result['user']['phone'] ?? identifier;
      
      // Check if user profile exists
      final profile = await _apiService.getUser(_userId!);
      _userProfileExists = profile != null;

      // Sync all user's data from backend MongoDB
      await loadAppData(_userId!);
    }

    _isLoading = false;
    notifyListeners();
    return result != null;
  }

  Future<void> loadAppData(String userId) async {
    try {
      // 1. User profile
      final userMap = await _apiService.getUser(userId);
      if (userMap != null) {
        MockData.currentUser = UserModel.fromMap(userMap, userId);
      }

      // 2. Fields
      final fieldsList = await _apiService.getFieldsStream(userId).first;
      MockData.fields.clear();
      MockData.fields.addAll(fieldsList.map((m) => FieldModel.fromMap(m, m['id'] ?? m['_id'])));

      // 3. Crops
      MockData.crops.clear();
      for (final f in MockData.fields) {
        final cropsList = await _apiService.getCropsStream(f.id).first;
        MockData.crops.addAll(cropsList.map((m) => CropModel.fromMap(m, m['id'] ?? m['_id'])));
      }

      // 4. Activities
      MockData.activities.clear();
      for (final c in MockData.crops) {
        final actList = await _apiService.getActivitiesStream(c.id).first;
        MockData.activities.addAll(actList.map((m) => ActivityModel.fromMap(m, m['id'] ?? m['_id'])));
      }

      // 5. Action Points
      final apList = await _apiService.getActionPointsStream(scope: 'farmer', refId: userId).first;
      MockData.actionPoints.clear();
      MockData.actionPoints.addAll(apList.map((m) => ActionPointModel.fromMap(m, m['id'] ?? m['_id'])));

      // 6. Financials
      MockData.financials.clear();
      for (final c in MockData.crops) {
        final finMap = await _apiService.getFinancials(c.id);
        if (finMap != null) {
          MockData.financials.add(FinancialModel.fromMap(finMap, finMap['id'] ?? finMap['_id'] ?? c.id));
        }
      }
      
      debugPrint('[AuthService] Successfully loaded user app data from MongoDB.');
    } catch (e) {
      debugPrint('[AuthService] Error loading user app data from MongoDB: $e');
    }
  }

  Future<void> signOut() async {
    _isAuthenticated = false;
    _userId = null;
    _phoneNumber = null;
    _userProfileExists = false;
    notifyListeners();
    // clear tokens from storage
  }

  void devLogin() {
    _isAuthenticated = true;
    _userId = 'user_001';
    _phoneNumber = '+91 98765 43210';
    _userProfileExists = true;
    loadAppData('user_001').then((_) {
      notifyListeners();
    });
  }
}
