// lib/core/constants/app_constants.dart
// ─────────────────────────────────────────────────────────────
// Central place for all constant values used across the app.
// Change the baseUrl here when deploying to Railway (production).
// ─────────────────────────────────────────────────────────────

class AppConstants {
  // — API ───────────────────────────────────────────────────
  // Production (Railway):
  // static const String baseUrl = 'http://127.0.0.1:8000';
  static const String baseUrl = 'https://api.jagrukdurbe.in';
  // Development (local FastAPI on Mac): uncomment to use, then run
  //   `ipconfig getifaddr en0` on Mac and update the IP if it changed.
  // static const String baseUrl = 'http://192.168.0.121:8000';
  // Note: 10.0.2.2 is how Android emulator reaches your Mac's localhost
  // For real device on same WiFi, use your Mac's local IP e.g. 192.168.0.189

  // — Village ───────────────────────────────────────────────
  static const String villageId = '1';
  static const String villageName = 'Durbe';
  static const String villageDistrict = 'Gaya, Bihar';

  // — App info ──────────────────────────────────────────────
  static const String appName = 'Jagruk Durbe';
  static const String appTagline = 'Jagruk Durbe';
  static const String appTaglineHindi = 'जागरूक दुर्बे';

  // — Storage keys (shared_preferences) ────────────────────
  static const String tokenKey = 'access_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userRoleKey = 'user_role';
  static const String isVerifiedKey = 'is_verified';
}