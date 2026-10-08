import 'dart:convert';

import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/utils/network_utility.dart'
    show sessionRevision;
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'registered_device_token';

Future<SharedPreferences> _setUp({required bool loggedIn}) async {
  SharedPreferences.setMockInitialValues({_key: 'fcm-token-of-rider-a'});
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  FlutterSecureStorage.setMockInitialValues({
    if (loggedIn) ...{
      'auth_token': 'sanctum-token',
      'user_data': jsonEncode({'id': 1}),
    },
  });
  final session = UserSessionManager(const FlutterSecureStorage());
  await session.load();
  sl.registerSingleton<UserSessionManager>(session);
  return prefs;
}

void main() {
  tearDown(sl.reset);

  test('a 401 that ends the session forgets the registered push token',
      () async {
    final prefs = await _setUp(loggedIn: false);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(riderAuthProvider);

    // What RiderDioInterceptor does after clearing the session on a 401.
    sessionRevision.value++;
    await Future<void>.delayed(Duration.zero);

    // So the next rider to sign in registers their own token instead of
    // being skipped as "already registered".
    expect(prefs.getString(_key), isNull);
  });

  test('a revision bump while still signed in keeps the registration',
      () async {
    final prefs = await _setUp(loggedIn: true);
    expect(sl<UserSessionManager>().isLoggedIn, isTrue,
        reason: 'fixture must produce a signed-in session');
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(riderAuthProvider);

    sessionRevision.value++;
    await Future<void>.delayed(Duration.zero);

    expect(prefs.getString(_key), 'fcm-token-of-rider-a');
  });
}
