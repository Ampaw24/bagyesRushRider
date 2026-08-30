import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:delivery_boy/constant/baseurl.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';

/// Bumped whenever the session is invalidated out-of-band (a 401).
///
/// GoRouter's `redirect` only runs on navigation, so without a listenable
/// a rider already sitting on a screen would never be sent back to login —
/// they'd just watch every request fail. `createAppRouter` passes this as
/// `refreshListenable`.
final sessionRevision = ValueNotifier<int>(0);

/// Auth endpoints must not trigger the session-clearing 401 handler: a
/// wrong-password response is a normal outcome, not an expired session.
const _authPathFragments = [
  '/login',
  '/register',
  '/phone/',
  '/password/',
];

class NetworkUtility {
  NetworkUtility._();

  static Dio createDio(UserSessionManager sessionManager) {
    final dio = Dio(
      BaseOptions(
        baseUrl: kBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = sessionManager.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          final path = error.requestOptions.path;
          final isAuthPath = _authPathFragments.any(path.contains);

          if (error.response?.statusCode == 401 && !isAuthPath) {
            // Awaited: an un-awaited clear lets a concurrent request read
            // the stale token before it's actually gone.
            await sessionManager.clearSession();
            // Wakes GoRouter's redirect so the guard can send us to login.
            sessionRevision.value++;
          }
          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    return dio;
  }
}
