import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/rider_location_service.dart';
import 'package:delivery_boy/core/services/rider_online_intent.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/tracking/providers/rider_tracking_providers.dart';

/// What [RiderPresenceNotifier.sync] should do after comparing the rider's
/// intent, the server's view and the location permission.
enum PresenceAction {
  /// Nothing to correct.
  none,

  /// Server says online and everything is in order: make sure the GPS loop
  /// is really running and ping now.
  ensureTracking,

  /// The server dropped the rider (stale pings) but the rider never chose to
  /// go offline: put them back.
  restoreOnline,

  /// "Always" location is gone, so the rider can't be reliably visible.
  permissionLost,
}

/// Pure decision behind [RiderPresenceNotifier.sync], kept free of Riverpod so
/// it can be tested exhaustively.
///
/// [wantsOnline] is the rider's own last choice (see [RiderOnlineIntent]);
/// `null` means they never made one, and nothing is restored.
PresenceAction decidePresenceAction({
  required bool serverOnline,
  required bool? wantsOnline,
  required bool canGoOnline,
  required bool hasAlwaysPermission,
}) {
  if (serverOnline) {
    return hasAlwaysPermission
        ? PresenceAction.ensureTracking
        : PresenceAction.permissionLost;
  }
  if (wantsOnline == true && canGoOnline) {
    return hasAlwaysPermission
        ? PresenceAction.restoreOnline
        : PresenceAction.permissionLost;
  }
  return PresenceAction.none;
}

class RiderPresenceState extends Equatable {
  /// Set when "Always" location was withdrawn while the rider was (or meant
  /// to be) online. The dashboard shows the explainer and acknowledges it.
  final bool permissionLost;

  const RiderPresenceState({this.permissionLost = false});

  @override
  List<Object?> get props => [permissionLost];
}

/// Keeps the server's idea of the rider's presence matching what the rider
/// actually chose, across the app being minimized, left dormant or killed.
///
/// "Online" is a server flag plus a stream of location pings; neither is
/// re-asserted by anything on its own when the app comes back. This does it,
/// on every resume and on the dashboard's first build.
class RiderPresenceNotifier extends Notifier<RiderPresenceState> {
  bool _syncing = false;

  @override
  RiderPresenceState build() => const RiderPresenceState();

  /// Re-reads the server's view of the rider and corrects any drift. Cheap and
  /// idempotent; overlapping calls collapse into one. [reload] is false when
  /// the caller has only just loaded the profile itself.
  Future<void> sync({bool reload = true}) async {
    if (_syncing || !sl<UserSessionManager>().isLoggedIn) return;
    _syncing = true;
    try {
      if (reload) {
        await ref.read(riderMeProfileProvider.notifier).refreshSilently();
      }
      final profile = ref.read(riderMeProfileProvider).profile;
      if (profile == null) return;

      final serverOnline = profile.isOnline ?? false;
      final action = decidePresenceAction(
        serverOnline: serverOnline,
        wantsOnline: await RiderOnlineIntent.read(),
        canGoOnline: profile.canGoOnline,
        hasAlwaysPermission: await RiderLocationService.hasAlwaysPermission(),
      );

      switch (action) {
        case PresenceAction.none:
          return;
        case PresenceAction.ensureTracking:
          await ref.read(riderTrackingProvider.notifier).ensureRunning();
        case PresenceAction.restoreOnline:
          appLogger.i('[Presence] server dropped the rider — restoring online');
          final restored = await ref
              .read(riderMeProfileProvider.notifier)
              .setAvailability(true);
          if (restored) {
            await ref.read(riderTrackingProvider.notifier).ensureRunning();
          }
        case PresenceAction.permissionLost:
          await _handlePermissionLost(serverOnline: serverOnline);
          return;
      }

      // Offers only flow while online, and the socket/poll that normally
      // delivers them was frozen with the app.
      unawaited(ref.read(riderMeOffersProvider.notifier).load(silent: true));
    } catch (e, s) {
      appLogger.e('[Presence] sync failed', error: e, stackTrace: s);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _handlePermissionLost({required bool serverOnline}) async {
    // A rider mid-delivery keeps their status — dropping them offline under
    // an active order would be worse than a warning. Everyone else goes
    // offline rather than sitting "online" without sharing location.
    final onDelivery = ref.read(shouldTrackLocationProvider);
    if (!onDelivery) {
      if (serverOnline) {
        await ref.read(riderMeProfileProvider.notifier).setAvailability(false);
      } else {
        // The rider can't be restored without the permission; stop trying so
        // the explainer isn't raised on every resume.
        await RiderOnlineIntent.write(false);
      }
    }
    state = const RiderPresenceState(permissionLost: true);
  }

  void acknowledgePermissionLost() => state = const RiderPresenceState();
}

final riderPresenceProvider =
    NotifierProvider<RiderPresenceNotifier, RiderPresenceState>(
        RiderPresenceNotifier.new);
