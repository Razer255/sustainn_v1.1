import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'mock_data.dart';

/// API Service providing CRUD operations for all entities via REST.
/// Replace `_baseUrl` with your actual backend URL.
class ApiService {
  final String _baseUrl = 'https://sustainn-v1-1.onrender.com/api';
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ─── Authentication ──────────────────────────────────────────

  Future<Map<String, dynamic>?> login(String identifier, String password) async {
    debugPrint('[ApiService] login($identifier)');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'password': password}),
      ).timeout(const Duration(seconds: 45));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          setAuthToken(data['token']);
        }
        return data; // e.g. {'token': '...', 'user': {...}}
      }
      debugPrint('Login failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error logging in: $e.');
      return null;
    }
  }

  // ─── Users ──────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUser(String userId) async {
    debugPrint('[ApiService] getUser($userId)');
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error getting user: $e. Falling back to local data.');
    }
    return MockData.currentUser.toMap();
  }

  Future<void> createUser(String userId, Map<String, dynamic> data) async {
    debugPrint('[ApiService] createUser($userId)');
    try {
      final payload = Map<String, dynamic>.from(data)..['id'] = userId;
      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create user');
      }
    } catch (e) {
      debugPrint('Error creating user: $e. Saving locally to MockData.');
      try {
        final userModel = UserModel.fromMap(data, userId);
        MockData.currentUser = userModel;
      } catch (ex) {
        debugPrint('Error parsing user data: $ex');
      }
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    debugPrint('[ApiService] updateUser($userId)');
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: _headers,
        body: jsonEncode(data),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update user');
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  // ─── Fields ─────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getFieldsStream(String ownerId) async* {
    debugPrint('[ApiService] getFieldsStream($ownerId)');
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fields?ownerId=$ownerId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        yield data.cast<Map<String, dynamic>>();
      } else {
        yield [];
      }
    } catch (e) {
      debugPrint('Error getting fields stream: $e');
      yield [];
    }
  }

  Future<String> addField(Map<String, dynamic> data) async {
    debugPrint('[ApiService] addField(${data['name']})');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/fields'),
        headers: _headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData['id'] ?? 'generated_field_id';
      }
      throw Exception('Failed to add field');
    } catch (e) {
      debugPrint('Error adding field: $e');
      rethrow;
    }
  }

  Future<void> updateField(String fieldId, Map<String, dynamic> data) async {
    debugPrint('[ApiService] updateField($fieldId)');
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/fields/$fieldId'),
        headers: _headers,
        body: jsonEncode(data),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update field');
      }
    } catch (e) {
      debugPrint('Error updating field: $e');
      rethrow;
    }
  }

  Future<void> deleteField(String fieldId) async {
    debugPrint('[ApiService] deleteField($fieldId)');
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/fields/$fieldId'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete field');
      }
    } catch (e) {
      debugPrint('Error deleting field: $e');
      rethrow;
    }
  }

  // ─── Crops ──────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getCropsStream(String fieldId) async* {
    debugPrint('[ApiService] getCropsStream($fieldId)');
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/crops?fieldId=$fieldId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        yield data.cast<Map<String, dynamic>>();
      } else {
        yield [];
      }
    } catch (e) {
      debugPrint('Error getting crops stream: $e');
      yield [];
    }
  }

  Future<String> addCrop(Map<String, dynamic> data) async {
    debugPrint('[ApiService] addCrop(${data['cropName']})');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/crops'),
        headers: _headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData['id'] ?? 'generated_crop_id';
      }
      throw Exception('Failed to add crop');
    } catch (e) {
      debugPrint('Error adding crop: $e');
      rethrow;
    }
  }

  Future<void> updateCrop(String cropId, Map<String, dynamic> data) async {
    debugPrint('[ApiService] updateCrop($cropId)');
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/crops/$cropId'),
        headers: _headers,
        body: jsonEncode(data),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update crop');
      }
    } catch (e) {
      debugPrint('Error updating crop: $e');
      rethrow;
    }
  }

  // ─── Activities ─────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getActivitiesStream(String cropId) async* {
    debugPrint('[ApiService] getActivitiesStream($cropId)');
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/activities?cropId=$cropId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        yield data.cast<Map<String, dynamic>>();
      } else {
        yield [];
      }
    } catch (e) {
      debugPrint('Error getting activities stream: $e');
      yield [];
    }
  }

  Future<String> addActivity(Map<String, dynamic> data) async {
    debugPrint('[ApiService] addActivity(${data['type']})');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/activities'),
        headers: _headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData['id'] ?? 'generated_activity_id';
      }
      throw Exception('Failed to add activity');
    } catch (e) {
      debugPrint('Error adding activity: $e');
      rethrow;
    }
  }

  // ─── Location (LGD) ─────────────────────────────────────────
  // State → District → Tehsil → Village cascade for Signup, proxied
  // through the backend so the data.gov.in API key stays server-side.

  Future<List<LocationOption>> getStates() async {
    debugPrint('[ApiService] getStates()');
    return _getLocationOptions('$_baseUrl/location/states');
  }

  Future<List<LocationOption>> getDistricts(int stateCode) async {
    debugPrint('[ApiService] getDistricts($stateCode)');
    return _getLocationOptions('$_baseUrl/location/districts?stateCode=$stateCode');
  }

  Future<List<LocationOption>> getSubdistricts(int districtCode) async {
    debugPrint('[ApiService] getSubdistricts($districtCode)');
    return _getLocationOptions('$_baseUrl/location/subdistricts?districtCode=$districtCode');
  }

  Future<List<LocationOption>> getVillages(int subdistrictCode) async {
    debugPrint('[ApiService] getVillages($subdistrictCode)');
    return _getLocationOptions('$_baseUrl/location/villages?subdistrictCode=$subdistrictCode');
  }

  Future<List<LocationOption>> _getLocationOptions(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => LocationOption.fromMap(e)).toList();
      }
      debugPrint('Location API error: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error fetching location options: $e');
      return [];
    }
  }

  // ─── Action Points ─────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getActionPointsStream({
    required String scope,
    required String refId,
  }) async* {
    debugPrint('[ApiService] getActionPointsStream($scope, $refId)');
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/action-points?scope=$scope&refId=$refId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        yield data.cast<Map<String, dynamic>>();
      } else {
        yield [];
      }
    } catch (e) {
      debugPrint('Error getting action points stream: $e');
      yield [];
    }
  }

  Future<void> resolveActionPoint(String actionPointId) async {
    debugPrint('[ApiService] resolveActionPoint($actionPointId)');
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/action-points/$actionPointId/resolve'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to resolve action point');
      }
    } catch (e) {
      debugPrint('Error resolving action point: $e');
      rethrow;
    }
  }

  // ─── Financials ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> getFinancials(String cropId) async {
    debugPrint('[ApiService] getFinancials($cropId)');
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/financials/$cropId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error getting financials: $e');
    }
    return null;
  }

  Future<void> updateFinancials(
      String cropId, Map<String, dynamic> data) async {
    debugPrint('[ApiService] updateFinancials($cropId)');
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/financials/$cropId'),
        headers: _headers,
        body: jsonEncode(data),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update financials');
      }
    } catch (e) {
      debugPrint('Error updating financials: $e');
      rethrow;
    }
  }
}

/// One State/District/Tehsil/Village option in the LGD cascade (§ Signup).
class LocationOption {
  final int code;
  final String name;

  const LocationOption({required this.code, required this.name});

  factory LocationOption.fromMap(Map<String, dynamic> map) {
    return LocationOption(
      code: (map['code'] as num).toInt(),
      name: map['name'] ?? '',
    );
  }
}
