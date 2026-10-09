import 'package:flutter_test/flutter_test.dart';

import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/tracking/providers/rider_presence_providers.dart';

PresenceAction decide({
  bool serverOnline = false,
  bool? wantsOnline,
  bool canGoOnline = true,
  bool hasAlways = true,
}) =>
    decidePresenceAction(
      serverOnline: serverOnline,
      wantsOnline: wantsOnline,
      canGoOnline: canGoOnline,
      hasAlwaysPermission: hasAlways,
    );

void main() {
  group('decidePresenceAction', () {
    test('online server + Always permission just keeps tracking alive', () {
      expect(decide(serverOnline: true), PresenceAction.ensureTracking);
      expect(decide(serverOnline: true, wantsOnline: true),
          PresenceAction.ensureTracking);
    });

    test('online server without Always permission is a permission loss', () {
      expect(decide(serverOnline: true, hasAlways: false),
          PresenceAction.permissionLost);
    });

    test('server dropped a rider who chose online → restore', () {
      expect(decide(wantsOnline: true), PresenceAction.restoreOnline);
    });

    test('a rider who chose offline is never put back online', () {
      expect(decide(wantsOnline: false), PresenceAction.none);
    });

    test('a rider who never chose anything is left alone', () {
      expect(decide(wantsOnline: null), PresenceAction.none);
    });

    test('cannot restore a rider the server will not let online', () {
      expect(decide(wantsOnline: true, canGoOnline: false), PresenceAction.none);
    });

    test('cannot restore without Always permission', () {
      expect(decide(wantsOnline: true, hasAlways: false),
          PresenceAction.permissionLost);
    });
  });

  group('RiderMeLocationPing persistence', () {
    test('survives a toJson → fromJson round trip', () {
      final ping = RiderMeLocationPing(
        latitude: 5.6037,
        longitude: -0.187,
        heading: 90,
        speedKph: 21.6,
        accuracyM: 12,
        recordedAt: DateTime.utc(2026, 10, 9, 12, 30, 15),
      );
      expect(RiderMeLocationPing.fromJson(ping.toJson()), ping);
    });

    test('optional fields stay absent', () {
      final ping = RiderMeLocationPing(
        latitude: 5.6,
        longitude: -0.18,
        recordedAt: DateTime.utc(2026, 10, 9),
      );
      final restored = RiderMeLocationPing.fromJson(ping.toJson());
      expect(restored.heading, isNull);
      expect(restored.speedKph, isNull);
      expect(restored.accuracyM, isNull);
    });
  });
}
