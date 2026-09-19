import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PrefsHelper {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const String _isLoggedIn = 'is_logged_in';
  static const String _userName = 'user_name';
  static const String _userPhone = 'user_phone';
  static const String _userImage = 'user_image';
  static const String _isDarkMode = 'is_dark_mode';
  static const String _isArabic = 'is_arabic';
  static const String _activeSession = 'active_session';
  static const String _hasUsedCoupon = 'has_used_coupon';

  static bool get isLoggedIn => _prefs.getBool(_isLoggedIn) ?? false;
  static String get userName => _prefs.getString(_userName) ?? 'حسن إبراهيم';
  static String get userPhone => _prefs.getString(_userPhone) ?? '';
  static String? get userImage => _prefs.getString(_userImage);
  static bool get isDarkMode => _prefs.getBool(_isDarkMode) ?? false;
  static bool get isArabic => _prefs.getBool(_isArabic) ?? true;
  static bool get hasUsedCoupon => _prefs.getBool(_hasUsedCoupon) ?? false;
  
  static Map<String, dynamic>? get activeSession {
    final data = _prefs.getString(_activeSession);
    if (data == null) return null;
    return jsonDecode(data);
  }

  static Future<void> setLogin(String name, String phone) async {
    await _prefs.setBool(_isLoggedIn, true);
    await _prefs.setString(_userName, name);
    await _prefs.setString(_userPhone, phone);
  }

  static Future<void> logout() async {
    await _prefs.setBool(_isLoggedIn, false);
    await _prefs.remove(_activeSession);
    // Note: We don't reset _hasUsedCoupon on logout usually, 
    // but if the user wants it per user session we could.
    // Given "once per user", keeping it persisted makes sense.
  }

  static Future<void> setUsedCoupon(bool value) async {
    await _prefs.setBool(_hasUsedCoupon, value);
  }

  static Future<void> updateProfile({String? name, String? phone, String? image}) async {
    if (name != null) await _prefs.setString(_userName, name);
    if (phone != null) await _prefs.setString(_userPhone, phone);
    if (image != null) await _prefs.setString(_userImage, image);
  }

  static Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(_isDarkMode, value);
  }

  static Future<void> setLanguage(bool arabic) async {
    await _prefs.setBool(_isArabic, arabic);
  }

  static Future<void> saveActiveSession(Map<String, dynamic> session) async {
    await _prefs.setString(_activeSession, jsonEncode(session));
  }

  static Future<void> clearActiveSession() async {
    await _prefs.remove(_activeSession);
  }
}
