import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

  /// Fetches the user's profile. Throws on any failure (network error,
  /// timeout, non-200 response) rather than silently falling back to
  /// local mock data — a fallback here previously made a slow network
  /// show the seed demo user ("Rajesh Kumar") as if it were the real
  /// signed-in farmer, and risked overwriting their real profile on save.
  Future<Map<String, dynamic>> getUser(String userId) async {
    debugPrint('[ApiService] getUser($userId)');
    final response = await http.get(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Failed to load user profile (${response.statusCode}).');
    }
    return jsonDecode(response.body);
  }

  /// Creates the user's profile on the backend. Throws on any failure
  /// instead of silently saving to local mock data only — a caller that
  /// doesn't check for an exception must not be able to tell a real
  /// success from a failed request that was quietly absorbed here.
  Future<void> createUser(String userId, Map<String, dynamic> data) async {
    debugPrint('[ApiService] createUser($userId)');
    final payload = Map<String, dynamic>.from(data)..['id'] = userId;
    final response = await http.post(
      Uri.parse('$_baseUrl/users'),
      headers: _headers,
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create user (${response.statusCode}).');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    debugPrint('[ApiService] updateUser($userId)');
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 45));
      if (response.statusCode != 200) {
        throw Exception('Failed to update user');
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  /// Submits a problem report to the admin dashboard.
  Future<void> reportIssue({
    required String userId,
    required String userName,
    required String userPhone,
    required String message,
  }) async {
    debugPrint('[ApiService] reportIssue($userId)');
    final response = await http.post(
      Uri.parse('$_baseUrl/issue-reports'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'message': message,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to submit report.');
    }
  }

  /// Changes the user's password. Throws with a user-facing message on
  /// failure (wrong current password, validation error, network error).
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    debugPrint('[ApiService] changePassword($userId)');
    final response = await http.post(
      Uri.parse('$_baseUrl/users/$userId/change-password'),
      headers: _headers,
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      String message = 'Failed to change password.';
      try {
        final body = jsonDecode(response.body);
        if (body['error'] != null) message = body['error'];
      } catch (_) {}
      throw Exception(message);
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
      ).timeout(const Duration(seconds: 45));
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
    final response = await http.delete(
      Uri.parse('$_baseUrl/fields/$fieldId'),
      headers: _headers,
    ).timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      String message = 'Failed to delete field.';
      try {
        final body = jsonDecode(response.body);
        if (body['error'] != null) message = body['error'];
      } catch (_) {}
      throw Exception(message);
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
      ).timeout(const Duration(seconds: 45));
      if (response.statusCode != 200) {
        throw Exception('Failed to update crop');
      }
    } catch (e) {
      debugPrint('Error updating crop: $e');
      rethrow;
    }
  }

  Future<void> deleteCrop(String cropId) async {
    debugPrint('[ApiService] deleteCrop($cropId)');
    final response = await http.delete(
      Uri.parse('$_baseUrl/crops/$cropId'),
      headers: _headers,
    ).timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      String message = 'Failed to delete crop.';
      try {
        final body = jsonDecode(response.body);
        if (body['error'] != null) message = body['error'];
      } catch (_) {}
      throw Exception(message);
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

  Future<void> updateActivity(String activityId, Map<String, dynamic> data) async {
    debugPrint('[ApiService] updateActivity($activityId)');
    final response = await http.put(
      Uri.parse('$_baseUrl/activities/$activityId'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw Exception('Failed to update activity');
    }
  }

  Future<void> deleteActivity(String activityId) async {
    debugPrint('[ApiService] deleteActivity($activityId)');
    final response = await http.delete(
      Uri.parse('$_baseUrl/activities/$activityId'),
      headers: _headers,
    ).timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete activity');
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
