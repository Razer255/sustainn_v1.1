import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  static const _sessionUserIdKey = 'session_user_id';
  static const _sessionPhoneKey = 'session_phone';

  AuthService();

  /// Restores a previously saved session (if any) so the farmer isn't
  /// bounced back to the login screen every time the app process is
  /// killed and relaunched. Call once at startup, before the first frame.
  Future<void> tryAutoLogin() async {
    final prefsBox = await Hive.openBox('prefs');
    final savedUserId = prefsBox.get(_sessionUserIdKey) as String?;
    if (savedUserId == null) return;

    // The backend now requires a valid auth token on every request; the
    // token issued at login must be restored before any of the calls
    // below, or they'll all fail with 401.
    await ApiService.restoreAuthToken();

    _isAuthenticated = true;
    _userId = savedUserId;
    _phoneNumber = prefsBox.get(_sessionPhoneKey) as String?;

    // A saved session is restored even if the profile fetch fails here
    // (e.g. no network on cold start) — the farmer already has a valid
    // session and shouldn't be logged out just because the server was
    // briefly unreachable. loadAppData below has its own error handling
    // for the rest of the sync.
    try {
      await _apiService.getUser(savedUserId);
      _userProfileExists = true;
    } catch (e) {
      debugPrint('[AuthService] Could not refresh profile on auto-login: $e');
    }

    await loadAppData(savedUserId);
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _apiService.login(identifier, password);

    if (result != null) {
      _isAuthenticated = true;
      _userId = result['user']['id'];
      _phoneNumber = result['user']['phone'] ?? identifier;

      final prefsBox = await Hive.openBox('prefs');
      await prefsBox.put(_sessionUserIdKey, _userId);
      await prefsBox.put(_sessionPhoneKey, _phoneNumber);

      // Login already succeeded with valid credentials, so a hiccup
      // fetching the profile right after shouldn't fail the whole login.
      try {
        await _apiService.getUser(_userId!);
        _userProfileExists = true;
      } catch (e) {
        debugPrint('[AuthService] Could not fetch profile right after login: $e');
        _userProfileExists = true;
      }

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
      MockData.currentUser = UserModel.fromMap(userMap, userId);

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

      // 5. Action Points — farmer-level, plus field-level and crop-level
      // for every field/crop the farmer owns. Previously only farmer-level
      // ones were fetched, so field/crop action points (e.g. created from
      // the admin dashboard) never reached the app.
      MockData.actionPoints.clear();
      final farmerApList =
          await _apiService.getActionPointsStream(scope: 'farmer', refId: userId).first;
      MockData.actionPoints
          .addAll(farmerApList.map((m) => ActionPointModel.fromMap(m, m['id'] ?? m['_id'])));

      for (final f in MockData.fields) {
        final fieldApList =
            await _apiService.getActionPointsStream(scope: 'field', refId: f.id).first;
        MockData.actionPoints
            .addAll(fieldApList.map((m) => ActionPointModel.fromMap(m, m['id'] ?? m['_id'])));
      }

      for (final c in MockData.crops) {
        final cropApList =
            await _apiService.getActionPointsStream(scope: 'crop', refId: c.id).first;
        MockData.actionPoints
            .addAll(cropApList.map((m) => ActionPointModel.fromMap(m, m['id'] ?? m['_id'])));
      }

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

    MockData.resetForLogout();
    await ApiService.setAuthToken(null);

    final prefsBox = await Hive.openBox('prefs');
    await prefsBox.delete(_sessionUserIdKey);
    await prefsBox.delete(_sessionPhoneKey);

    notifyListeners();
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
