import 'dart:convert';

import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/auth/models/auth_user_model.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_avatar_providers.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/shared_widgets/rider_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _sessionPhoto = 'https://cdn.example.com/session.jpg';
const _riderMePhoto = 'https://cdn.example.com/rider-me.jpg';

class _LoadedProfileNotifier extends RiderMeProfileNotifier {
  @override
  RiderMeProfileState build() => const RiderMeProfileState(
        status: RiderMeProfileStatus.loaded,
        profile: RiderMeProfileModel(photoUrl: _riderMePhoto),
      );
}

Future<void> _registerSession(Map<String, dynamic>? user) async {
  FlutterSecureStorage.setMockInitialValues({
    if (user != null) 'user_data': jsonEncode(user),
  });
  final session = UserSessionManager(const FlutterSecureStorage());
  await session.load();
  sl.registerSingleton<UserSessionManager>(session);
}

void main() {
  group('RiderMeProfileModel.photoUrl', () {
    test('reads profile_photo_url', () {
      final model = RiderMeProfileModel.fromJson({
        'profile_photo_url': _riderMePhoto,
        'photo_url': 'https://cdn.example.com/old.jpg',
      });
      expect(model.photoUrl, _riderMePhoto);
    });

    test('falls back to photo_url', () {
      final model = RiderMeProfileModel.fromJson({'photo_url': _riderMePhoto});
      expect(model.photoUrl, _riderMePhoto);
    });

    test('treats a null or blank URL as no photo', () {
      expect(
        RiderMeProfileModel.fromJson({'profile_photo_url': null}).photoUrl,
        isNull,
      );
      expect(
        RiderMeProfileModel.fromJson({'profile_photo_url': '  '}).photoUrl,
        isNull,
      );
    });
  });

  group('AuthUserModel.profilePhotoUrl', () {
    test('survives the round trip the session store makes', () {
      final user = AuthUserModel.fromJson({
        'id': 7,
        'role': 'rider',
        'profile_photo_url': _sessionPhoto,
      });

      // UserSessionManager persists toJson() and later re-parses it.
      final restored = AuthUserModel.fromJson(user.toJson());
      expect(restored.profilePhotoUrl, _sessionPhoto);
    });

    test('is also read from inside profile', () {
      final user = AuthUserModel.fromJson({
        'id': 7,
        'profile': {'first_name': 'Ama', 'profile_photo_url': _sessionPhoto},
      });
      expect(user.profilePhotoUrl, _sessionPhoto);
    });
  });

  group('riderAvatarUrlProvider', () {
    tearDown(() => sl.reset());

    test('uses the saved session before /rider/me has loaded', () async {
      await _registerSession({'id': 7, 'profile_photo_url': _sessionPhoto});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(riderAvatarUrlProvider), _sessionPhoto);
    });

    test('prefers /rider/me once it has loaded', () async {
      await _registerSession({'id': 7, 'profile_photo_url': _sessionPhoto});
      final container = ProviderContainer(overrides: [
        riderMeProfileProvider.overrideWith(_LoadedProfileNotifier.new),
      ]);
      addTearDown(container.dispose);

      expect(container.read(riderAvatarUrlProvider), _riderMePhoto);
    });

    test('is null when no source has a photo', () async {
      await _registerSession({'id': 7});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(riderAvatarUrlProvider), isNull);
    });
  });

  group('RiderAvatar', () {
    Widget host(String? url) => MaterialApp(
          home: Scaffold(
            body: RiderAvatar(
              radius: 30,
              imageUrl: url,
              placeholder: const Text('AK'),
            ),
          ),
        );

    testWidgets('shows the placeholder when there is no photo',
        (tester) async {
      await tester.pumpWidget(host(null));
      expect(find.text('AK'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('keeps the placeholder when the photo fails to load',
        (tester) async {
      // flutter_test answers every HTTP request with a 400.
      await tester.pumpWidget(host('https://cdn.example.com/missing.jpg'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('AK'), findsOneWidget);
    });
  });
}
