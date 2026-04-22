import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';
import '../services/api_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();

  AuthState _state = AuthState.initial;
  Map<String, dynamic>? _profile;
  String? _phone;
  String? _errorMessage;
  bool _otpSent = false;
  bool _skippedOtp = false;  // true when backend issued token directly (returning customer)

  AuthState get state => _state;
  Map<String, dynamic>? get profile => _profile;
  String? get phone => _phone;
  String? get errorMessage => _errorMessage;
  bool get otpSent => _otpSent;
  bool get skippedOtp => _skippedOtp;
  bool get isAuthenticated => _state == AuthState.authenticated;

  // ── Initialize: Check for existing token ─────────────────────────────────
  Future<void> initialize() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final token = await ApiService.getToken();
      if (token == null) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return;
      }

      // Validate token by fetching profile
      final result = await ApiService.getProfile();
      if (result['success'] == true) {
        _profile = result['customer'];
        _phone = _profile?['phone'];
        _state = AuthState.authenticated;
      } else {
        await ApiService.clearToken();
        _state = AuthState.unauthenticated;
      }
    } catch (_) {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // ── Step 1: Request OTP (or direct login for returning customers) ──────────
  //
  // If the phone number is already verified, the backend skips Termii entirely
  // and returns a JWT directly (skipOtp: true). In that case we save the token
  // and move straight to authenticated state — no OTP entry needed.
  //
  // For brand-new numbers the backend sends an SMS and returns skipOtp: false,
  // and the normal OTP entry flow continues.
  Future<bool> requestOtp(String phone) async {
    _state = AuthState.loading;
    _errorMessage = null;
    _skippedOtp = false;
    notifyListeners();

    try {
      final result = await ApiService.requestOtp(phone);
      if (result['success'] == true) {
        _phone = phone;

        // ── Returning customer: backend issued token directly ──────────────
        final skipOtp = result['skipOtp'] == true;
        if (skipOtp && result['token'] != null) {
          await ApiService.saveToken(result['token'] as String);
          _profile = result['customer'] as Map<String, dynamic>?;
          _skippedOtp = true;
          _otpSent = false;
          _state = AuthState.authenticated;
          notifyListeners();
          return true;
        }

        // ── New customer: OTP SMS sent, show OTP entry screen ─────────────
        _otpSent = true;
        _state = AuthState.unauthenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to send OTP';
        _state = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection.';
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ── Step 2: Verify OTP ────────────────────────────────────────────────────
  Future<bool> verifyOtp(String otp) async {
    if (_phone == null) return false;
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.verifyOtp(_phone!, otp);
      if (result['success'] == true) {
        final token = result['token'] as String?;
        if (token != null) {
          await ApiService.saveToken(token);
        }
        _profile = result['customer'];
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Invalid OTP. Please try again.';
        _state = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection.';
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ── Building ID Fallback Login ────────────────────────────────────────────
  Future<bool> loginWithBuildingId(String buildingId, String phone) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.loginWithBuildingId(buildingId, phone);
      if (result['success'] == true) {
        final token = result['token'] as String?;
        if (token != null) {
          await ApiService.saveToken(token);
        }
        _profile = result['customer'];
        _phone = phone;
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Customer ID not found.';
        _state = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection.';
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ── Refresh Profile ───────────────────────────────────────────────────────
  Future<void> refreshProfile() async {
    try {
      final result = await ApiService.getProfile();
      if (result['success'] == true) {
        _profile = result['customer'];
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await ApiService.clearToken();
    _profile = null;
    _phone = null;
    _otpSent = false;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  void resetOtp() {
    _otpSent = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
