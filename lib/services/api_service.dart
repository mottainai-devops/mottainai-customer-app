import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();

  // ── Token Management ──────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Auth: Request OTP ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> requestOtp(String phone) async {
    final res = await http.post(
      Uri.parse('${AppConstants.customerAuthBase}/auth/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Auth: Verify OTP ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> verifyOtp(
      String phone, String otp) async {
    final res = await http.post(
      Uri.parse('${AppConstants.customerAuthBase}/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Auth: Building ID Fallback ────────────────────────────────────────────
  static Future<Map<String, dynamic>> loginWithBuildingId(
      String buildingId, String phone) async {
    final res = await http.post(
      Uri.parse('${AppConstants.customerAuthBase}/auth/building-id-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'buildingId': buildingId, 'phone': phone}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('${AppConstants.customerAuthBase}/profile'),
      headers: headers,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> data) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('${AppConstants.customerAuthBase}/profile'),
      headers: headers,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Pickups ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getPickups(
      {int page = 1, int limit = 20}) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse(
          '${AppConstants.customerAuthBase}/pickups?page=$page&limit=$limit'),
      headers: headers,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> requestPickup(
      Map<String, dynamic> data) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('${AppConstants.customerAuthBase}/pickup/request'),
      headers: headers,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Invoices ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getInvoices(
      {int page = 1, int limit = 20}) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse(
          '${AppConstants.customerAuthBase}/invoices?page=$page&limit=$limit'),
      headers: headers,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getInvoiceDetail(
      String invoiceId) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('${AppConstants.customerAuthBase}/invoices/$invoiceId'),
      headers: headers,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Payments ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> initiatePayment(
      String invoiceId, double amount) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('${AppConstants.customerAuthBase}/payment/initiate'),
      headers: headers,
      body: jsonEncode({'invoiceId': invoiceId, 'amount': amount}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> verifyPayment(String reference) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('${AppConstants.customerAuthBase}/payment/verify'),
      headers: headers,
      body: jsonEncode({'reference': reference}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── FCM Token Registration ────────────────────────────────────────────────
  static Future<void> registerFcmToken(String fcmToken) async {
    try {
      final headers = await _authHeaders();
      await http.post(
        Uri.parse('${AppConstants.customerAuthBase}/fcm-token'),
        headers: headers,
        body: jsonEncode({'fcmToken': fcmToken}),
      );
    } catch (_) {
      // Non-critical — swallow errors
    }
  }
}
