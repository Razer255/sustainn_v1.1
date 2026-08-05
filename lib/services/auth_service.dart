import 'package:flutter/foundation.dart';

/// Authentication service wrapping Firebase Auth.
/// Currently uses mock authentication for development.
/// Replace with Firebase Auth phone OTP once google-services.json is configured.
class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _userId;
  String? _phoneNumber;
  String? _verificationId;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userId => _userId;
  String? get phoneNumber => _phoneNumber;

  /// Send OTP to the given phone number.
  /// In production, this calls FirebaseAuth.verifyPhoneNumber.
  Future<bool> sendOtp(String phoneNumber) async {
    _isLoading = true;
    _phoneNumber = phoneNumber;
    notifyListeners();

    try {
      // Simulate OTP sending delay
      await Future.delayed(const Duration(seconds: 2));
      _verificationId = 'mock_verification_id';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error sending OTP: $e');
      return false;
    }
  }

  /// Verify the OTP entered by the user.
  /// In production, this creates a PhoneAuthCredential and signs in.
  Future<bool> verifyOtp(String otp) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate verification delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock: accept any 6-digit OTP
      if (otp.length == 6) {
        _isAuthenticated = true;
        _userId = 'user_001';
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error verifying OTP: $e');
      return false;
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    _isAuthenticated = false;
    _userId = null;
    _phoneNumber = null;
    _verificationId = null;
    notifyListeners();
  }

  /// Quick login for development (bypasses OTP).
  void devLogin() {
    _isAuthenticated = true;
    _userId = 'user_001';
    _phoneNumber = '+91 98765 43210';
    notifyListeners();
  }
}
