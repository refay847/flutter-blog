import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class TokenStorage {
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> saveToken(String token) async => (await _prefs).setString(AppConstants.tokenKey, token);
  Future<String?> getToken() async => (await _prefs).getString(AppConstants.tokenKey);
  Future<void> saveUser(Map<String, dynamic> user) async => (await _prefs).setString(AppConstants.userKey, jsonEncode(user));
  Future<Map<String, dynamic>?> getUser() async {
    final raw = (await _prefs).getString(AppConstants.userKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }
  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
  }
}
