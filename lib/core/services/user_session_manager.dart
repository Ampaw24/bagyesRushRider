import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserSessionManager {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';

  final SharedPreferences _prefs;

  UserSessionManager(this._prefs);

  String? get token => _prefs.getString(_tokenKey);

  bool get isLoggedIn {
    final t = token;
    return t != null && t.isNotEmpty;
  }

  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_userKey, jsonEncode(user));
  }

  Map<String, dynamic>? get currentUser {
    final raw = _prefs.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clearSession() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
  }
}
