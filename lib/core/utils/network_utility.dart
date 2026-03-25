import 'package:dio/dio.dart';
import 'package:delivery_boy/constant/baseurl.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';

class NetworkUtility {
  NetworkUtility._();

  static Dio createDio(UserSessionManager sessionManager) {
    final dio = Dio(
      BaseOptions(
        baseUrl: kBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
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
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            // Clear session; GoRouter redirect will handle navigation to login
            sessionManager.clearSession();
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
