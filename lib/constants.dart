/// App-wide constants for the Mottainai Customer App

class AppConstants {
  // ── API ──────────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://upwork.kowope.xyz/api/v1';
  static const String customerAuthBase = '$baseUrl/customer';
  static const String adminBase = '$baseUrl/admin';

  // ── App Info ─────────────────────────────────────────────────────────────
  static const String appName = 'Mottainai';
  static const String appTagline = 'Waste Management Made Easy';
  static const String supportWhatsApp = 'https://wa.me/2348000000000';

  // ── Paystack ─────────────────────────────────────────────────────────────
  static const String paystackPublicKey = 'pk_live_REPLACE_WITH_ACTUAL_KEY';

  // ── Storage Keys ─────────────────────────────────────────────────────────
  static const String tokenKey = 'customer_jwt_token';
  static const String phoneKey = 'customer_phone';
  static const String profileKey = 'customer_profile';

  // ── Colors ───────────────────────────────────────────────────────────────
  static const int primaryColorValue = 0xFF1B5E20; // Deep green
  static const int accentColorValue = 0xFF4CAF50;  // Medium green
  static const int surfaceColorValue = 0xFFF5F5F5;

  // ── Bin Types ─────────────────────────────────────────────────────────────
  static const List<String> binTypes = [
    '120L WHEELIE BIN',
    '240L WHEELIE BIN',
    '240 LITRE WHEELIE BIN',
    '660L WHEELIE BIN',
    '1100L WHEELIE BIN',
    'MAMMOTH (1100 LITRE)',
    '7-11 TONNE COMPACTOR',
    '6CBM SKIP BIN',
    '10 CBM SKIP BIN',
    '18 CBM DINO BIN',
    '27 CBM COMPACTOR',
    'SACHET',
  ];
}
