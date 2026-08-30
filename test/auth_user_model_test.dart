import 'package:delivery_boy/features/rider/auth/models/auth_user_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors `RiderAuthRepositoryImpl._parseAuth` so the envelope handling is
/// covered without standing up Dio.
({AuthUserModel user, String? token, String? refreshToken}) parseAuth(
  Map<String, dynamic> body,
) {
  final payload = (body['data'] as Map?)?.cast<String, dynamic>() ?? body;
  final userJson =
      (payload['user'] as Map?)?.cast<String, dynamic>() ?? payload;
  return (
    user: AuthUserModel.fromJson(userJson),
    token: payload['token'] as String? ?? payload['access_token'] as String?,
    refreshToken: payload['refresh_token'] as String?,
  );
}

void main() {
  group('AuthUserModel.fromJson', () {
    test('parses the documented user shape', () {
      final user = AuthUserModel.fromJson({
        'id': 42,
        'email': 'rider@example.com',
        'phone': '+233241234567',
        'role': 'rider',
        'status': 'active',
        'phone_verified': true,
        'profile': {'first_name': 'Ama', 'last_name': 'Mensah'},
      });

      expect(user.id, '42'); // numeric PK coerced, never cast
      expect(user.role, 'rider');
      expect(user.isRider, isTrue);
      expect(user.phoneVerified, isTrue);
      expect(user.fullName, 'Ama Mensah');
    });

    test('survives a null profile and missing keys', () {
      final user = AuthUserModel.fromJson({'id': 7});

      expect(user.id, '7');
      expect(user.profile, isNull);
      expect(user.fullName, '');
      expect(user.phoneVerified, isFalse);
    });

    test('treats a non-map profile as absent rather than throwing', () {
      final user = AuthUserModel.fromJson({'id': 1, 'profile': 'unexpected'});
      expect(user.profile, isNull);
    });

    test('round-trips through toJson', () {
      const original = AuthUserModel(
        id: '9',
        email: 'a@b.com',
        phone: '+233200000000',
        role: 'rider',
        status: 'active',
        phoneVerified: true,
        profile: {'first_name': 'Kofi'},
      );
      expect(AuthUserModel.fromJson(original.toJson()), original);
    });
  });

  group('auth response envelopes', () {
    test('{data: {user, token}}', () {
      final r = parseAuth({
        'data': {
          'token': 'tok',
          'refresh_token': 'ref',
          'user': {'id': 1, 'role': 'rider'},
        }
      });
      expect(r.token, 'tok');
      expect(r.refreshToken, 'ref');
      expect(r.user.id, '1');
    });

    test('{data: {...user, access_token}} — user fields inline', () {
      final r = parseAuth({
        'data': {'access_token': 'tok2', 'id': 2, 'role': 'rider'}
      });
      expect(r.token, 'tok2');
      expect(r.user.id, '2');
    });

    test('bare {user, token} with no data wrapper', () {
      final r = parseAuth({
        'token': 'tok3',
        'user': {'id': 3},
      });
      expect(r.token, 'tok3');
      expect(r.user.id, '3');
      expect(r.refreshToken, isNull);
    });

    test('a token-less register response still yields a user', () {
      final r = parseAuth({
        'data': {
          'user': {'id': 4}
        }
      });
      expect(r.token, isNull);
      expect(r.user.id, '4');
    });
  });
}
