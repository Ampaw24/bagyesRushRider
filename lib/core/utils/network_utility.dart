import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:delivery_boy/constant/baseurl.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';

/// Bumped whenever the session is invalidated out-of-band (a 401).
///
/// GoRouter's `redirect` only runs on navigation, so without a listenable
/// a rider already sitting on a screen would never be sent back to login —
/// they'd just watch every request fail. `createAppRouter` passes this as
/// `refreshListenable`.
final sessionRevision = ValueNotifier<int>(0);

/// Auth endpoints must not trigger the session-clearing 401 handler: a
/// wrong-password response is a normal outcome, not an expired session.
/// Also used to redact request/response bodies in debug logs, since these
/// paths carry passwords and OTP codes.
const _authPathFragments = [
  '/login',
  '/register',
  '/phone/',
  '/password/',
];

/// Attaches the bearer token, tags requests for the backend, and logs
/// request/response/error traffic with auth-sensitive bodies redacted.
///
/// This backend has no working refresh-token endpoint (`/auth/refresh-token`
/// returns 404), so unlike the sibling customer/vendor app's `DioInterceptor`
/// this one does not attempt a token-refresh-and-retry on 401 — it just
/// clears the session.
class RiderDioInterceptor extends Interceptor {
  RiderDioInterceptor(this._sessionManager);

  final UserSessionManager _sessionManager;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Platform'] = 'mobile';

    final token = _sessionManager.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    final isAuthPath = _authPathFragments.any(options.path.contains);
    final safeHeaders = Map<String, dynamic>.from(options.headers)
      ..remove('Authorization');

    appLogger.d(
      '[REQUEST] ${options.method} ${options.uri}\n'
      'Headers: $safeHeaders\n'
      'Body: ${isAuthPath ? '{REDACTED}' : options.data ?? 'none'}\n'
      'Query: ${options.queryParameters}',
    );

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final isAuthPath = _authPathFragments.any(response.requestOptions.path.contains);

    appLogger.d(
      '[RESPONSE] ${response.statusCode} ${response.requestOptions.uri}\n'
      'Data: ${isAuthPath ? '{REDACTED}' : response.data}',
    );

    handler.next(response);
  }

  @override
  Future<void> onError(DioException error, ErrorInterceptorHandler handler) async {
    final path = error.requestOptions.path;
    final isAuthPath = _authPathFragments.any(path.contains);

    appLogger.e(
      '[ERROR] ${error.type.name} ${error.requestOptions.uri}\n'
      'Status: ${error.response?.statusCode}\n'
      'Message: ${error.message}\n'
      'Response: ${isAuthPath ? '{REDACTED}' : error.response?.data}',
      error: error,
    );

    if (error.response?.statusCode == 401 && !isAuthPath) {
      // Awaited: an un-awaited clear lets a concurrent request read the
      // stale token before it's actually gone.
      await _sessionManager.clearSession();
      // Wakes GoRouter's redirect so the guard can send us to login.
      sessionRevision.value++;
    }

    handler.next(error);
  }
}

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

    dio.interceptors.add(RiderDioInterceptor(sessionManager));

    return dio;
  }
}
