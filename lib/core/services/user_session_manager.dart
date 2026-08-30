import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the signed-in session (tokens + the raw user JSON).
///
/// [currentUser] is an untyped map so it can round-trip whatever the API
/// returns. Prefer the typed accessors below over indexing it directly —
/// they carry the fallbacks that keep sessions written by older builds
/// readable after an upgrade.
class UserSessionManager {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';

  final SharedPreferences _prefs;

  UserSessionManager(this._prefs);

  String? get token => _prefs.getString(_tokenKey);

  String? get refreshToken => _prefs.getString(_refreshTokenKey);

  bool get isLoggedIn {
    final t = token;
    return t != null && t.isNotEmpty;
  }

  Map<String, dynamic>? get currentUser {
    final raw = _prefs.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Typed accessors ─────────────────────────────────────────────────────
  // The `_id` / `name` fallbacks read sessions written by the pre-Laravel
  // build, so upgrading the app doesn't force a logout.

  /// Backend user id. `id` (Laravel) with a legacy `_id` fallback.
  String? get userId => (currentUser?['id'] ?? currentUser?['_id'])?.toString();

  String? get email => currentUser?['email'] as String?;

  String? get phone => currentUser?['phone'] as String?;

  String? get role => currentUser?['role'] as String?;

  bool get isPhoneVerified => currentUser?['phone_verified'] == true;

  /// Human-readable name: `profile.first_name last_name`, falling back to
  /// the legacy flat `name` / `fullName` keys.
  String? get displayName {
    final user = currentUser;
    if (user == null) return null;

    final profile = user['profile'];
    if (profile is Map) {
      final parts = [profile['first_name'], profile['last_name']]
          .whereType<String>()
          .where((e) => e.trim().isNotEmpty)
          .toList();
      if (parts.isNotEmpty) return parts.join(' ');
    }

    final legacy = (user['name'] ?? user['fullName']) as String?;
    if (legacy != null && legacy.trim().isNotEmpty) return legacy;
    return null;
  }

  // ── Mutations ───────────────────────────────────────────────────────────

  Future<void> saveSession({
    required String token,
    String? refreshToken,
    required Map<String, dynamic> user,
  }) async {
    await _prefs.setString(_tokenKey, token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _prefs.setString(_refreshTokenKey, refreshToken);
    }
    await _prefs.setString(_userKey, jsonEncode(user));
  }

  Future<void> saveTokens({
    required String token,
    String? refreshToken,
  }) async {
    await _prefs.setString(_tokenKey, token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  /// Merges [patch] into the stored user without touching the tokens.
  ///
  /// Use this instead of re-calling [saveSession] with `token!` — that
  /// pattern throws when the token has already been cleared (e.g. by a 401).
  Future<void> updateUser(Map<String, dynamic> patch) async {
    final merged = {...?currentUser, ...patch};
    await _prefs.setString(_userKey, jsonEncode(merged));
  }

  /// Replaces the stored user wholesale, leaving the tokens intact.
  Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs.setString(_userKey, jsonEncode(user));
  }

  Future<void> clearSession() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userKey);
  }
}
