import 'dart:convert';
import 'dart:typed_data';

import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/auth/repositories/rider_auth_repository.dart';
import 'package:delivery_boy/features/rider/auth/repositories/rider_auth_repository_impl.dart';
import 'package:delivery_boy/features/rider/auth/services/rider_auth_api_service.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers `/login` with [status] and [body].
class _Server implements HttpClientAdapter {
  _Server(this.status, this.body);
  final int status;
  final Object body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });

  @override
  void close({bool force = false}) {}
}

/// A successful `/login` for an account with [role] (omitted when null).
Map<String, dynamic> _success(String? role) => {
      'success': true,
      'data': {
        'token': 'sanctum-token',
        'user': {'id': 7, 'phone': '233241234567', if (role != null) 'role': role},
      },
    };

/// The live server's answer to a wrong phone or password.
const _wrongPassword = {
  'success': false,
  'message': 'Invalid credentials',
  'errors': {
    'email': ['Invalid credentials'],
  },
};

RiderAuthRepositoryImpl _repo(int status, Object body) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
    ..httpClientAdapter = _Server(status, body);
  return RiderAuthRepositoryImpl(RiderAuthApiService(dio));
}

Future<Failure?> _loginFailure(int status, Object body) async {
  final result =
      await _repo(status, body).login(phone: '233241234567', password: 'pw');
  return result.fold((f) => f, (_) => null);
}

void main() {
  group('riders get in', () {
    for (final role in ['rider', 'delivery', ' Rider ']) {
      test('role "$role"', () async {
        final result = await _repo(200, _success(role))
            .login(phone: '233241234567', password: 'pw');
        expect(result.isRight(), isTrue);
        result.fold((_) {}, (auth) => expect(auth.token, 'sanctum-token'));
      });
    }
  });

  group('any other account looks exactly like a wrong password', () {
    late Failure wrongPassword;
    setUpAll(() async => wrongPassword = (await _loginFailure(422, _wrongPassword))!);

    for (final role in ['customer', 'vendor', 'admin', null]) {
      test('role ${role ?? 'missing'}', () async {
        final failure = await _loginFailure(200, _success(role));
        expect(failure, isA<ValidationFailure>());
        expect(failure!.message, wrongPassword.message);
        expect((failure as ValidationFailure).errors,
            (wrongPassword as ValidationFailure).errors);
      });
    }
  });

  test('a refused account is never signed in on this device', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final session = UserSessionManager(const FlutterSecureStorage());
    await session.load();
    sl.registerSingleton<UserSessionManager>(session);
    sl.registerSingleton<RiderAuthRepository>(_repo(200, _success('vendor')));
    addTearDown(sl.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final ok = await container
        .read(riderAuthProvider.notifier)
        .login(phone: '233241234567', password: 'correct-vendor-password');

    expect(ok, isFalse);
    expect(container.read(riderAuthProvider).errorMessage, 'Invalid credentials');
    expect(session.isLoggedIn, isFalse);
    expect(await const FlutterSecureStorage().read(key: 'auth_token'), isNull);
  });
}
