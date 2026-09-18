import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:delivery_boy/core/utils/json_utils.dart';

/// Persists the signed-in session (tokens + the raw user JSON) in the
/// platform keychain/keystore via [FlutterSecureStorage].
///
/// Reads are served from an in-memory cache hydrated by [load] — callers
/// throughout the app (router guards, providers, viewmodels) read [token],
/// [currentUser], etc. synchronously, and secure storage has no sync read
/// API. [load] must be awaited once at startup, before anything that reads
/// these getters (in particular, before the Dio interceptor is built).
///
/// [currentUser] is an untyped map so it can round-trip whatever the API
/// returns. Prefer the typed accessors below over indexing it directly —
/// they carry the fallbacks that keep sessions written by older builds
/// readable after an upgrade.
class UserSessionManager {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';

  final FlutterSecureStorage _storage;

  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? _currentUser;

  UserSessionManager(this._storage);

  /// Hydrates the in-memory session from secure storage. Call once at
  /// startup before any getter is read.
  Future<void> load() async {
    _token = await _storage.read(key: _tokenKey);
    _refreshToken = await _storage.read(key: _refreshTokenKey);
    final raw = await _storage.read(key: _userKey);
    _currentUser = raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  String? get token => _token;

  String? get refreshToken => _refreshToken;

  bool get isLoggedIn {
    final t = token;
    return t != null && t.isNotEmpty;
  }

  Map<String, dynamic>? get currentUser => _currentUser;

  // ── Typed accessors ─────────────────────────────────────────────────────
  // The `_id` / `name` fallbacks read sessions written by the pre-Laravel
  // build, so upgrading the app doesn't force a logout.

  /// Backend user id. `id` (Laravel) with a legacy `_id` fallback.
  String? get userId => (currentUser?['id'] ?? currentUser?['_id'])?.toString();

  String? get email => currentUser?['email'] as String?;

  String? get phone => currentUser?['phone'] as String?;

  String? get role => currentUser?['role'] as String?;

  bool get isPhoneVerified => currentUser?['phone_verified'] == true;

  String? get firstName => (currentUser?['profile'] as Map?)?['first_name'] as String?;

  String? get lastName => (currentUser?['profile'] as Map?)?['last_name'] as String?;

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

  /// The account photo, or null when there is none. Top-level (as
  /// [AuthUserModel.toJson] writes it) or inside `profile`.
  String? get profilePhotoUrl =>
      nonEmptyString(currentUser?['profile_photo_url']) ??
      nonEmptyString((currentUser?['profile'] as Map?)?['profile_photo_url']);

  // ── Mutations ───────────────────────────────────────────────────────────

  Future<void> saveSession({
    required String token,
    String? refreshToken,
    required Map<String, dynamic> user,
  }) async {
    _token = token;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
    }
    _currentUser = user;

    await _storage.write(key: _tokenKey, value: token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    await _storage.write(key: _userKey, value: jsonEncode(user));
  }

  Future<void> saveTokens({
    required String token,
    String? refreshToken,
  }) async {
    _token = token;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
    }

    await _storage.write(key: _tokenKey, value: token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  /// Merges [patch] into the stored user without touching the tokens.
  ///
  /// Use this instead of re-calling [saveSession] with `token!` — that
  /// pattern throws when the token has already been cleared (e.g. by a 401).
  Future<void> updateUser(Map<String, dynamic> patch) async {
    _currentUser = {...?_currentUser, ...patch};
    await _storage.write(key: _userKey, value: jsonEncode(_currentUser));
  }

  /// Replaces the stored user wholesale, leaving the tokens intact.
  Future<void> saveUser(Map<String, dynamic> user) async {
    _currentUser = user;
    await _storage.write(key: _userKey, value: jsonEncode(user));
  }

  Future<void> clearSession() async {
    _token = null;
    _refreshToken = null;
    _currentUser = null;

    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }
}
