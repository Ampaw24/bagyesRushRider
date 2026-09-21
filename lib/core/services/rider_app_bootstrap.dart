import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/realtime/realtime_service.dart';
import 'package:delivery_boy/core/router/app_router.dart';
import 'package:delivery_boy/core/services/fcm_service.dart';
import 'package:delivery_boy/core/services/firebase_bootstrap.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/location/providers/rider_location_providers.dart';

/// Non-critical startup work: OS permission prompts, the first GPS fix, and
/// push-token registration.
///
/// Run fire-and-forget from `main()` *after* `runApp()`, deliberately not
/// from the splash screen:
///
/// * `main()` runs exactly once. `SplashScreen.initState` can run again — the
///   router may re-enter `/`, and it's the target of a `refreshListenable`
///   bump on a 401. Firing permission prompts twice is precisely the
///   concurrency hazard `RiderLocationService`'s in-flight guards exist for.
/// * It overlaps the splash's own delay, so by the time the rider reaches the
///   home screen the address is usually already resolved and cached.
/// * It keeps service initialization out of a widget.
class RiderAppBootstrap {
  RiderAppBootstrap._();

  static bool _hasRun = false;

  static Future<void> run(ProviderContainer container) async {
    if (_hasRun) return;
    _hasRun = true;

    // Each step is separately guarded rather than sharing one try/catch:
    // a missing Firebase config must not stop the location steps running.
    await _initPush(container);
    await _initLocation(container);
    await _registerTokenIfSessionRestored(container);
    await _initRealtime();
  }

  /// Notifications first: a single binary prompt, whereas location can chain
  /// two dialogs. Awaited so the two OS prompts are strictly sequential —
  /// two concurrent permission dialogs is how you get a callback that never
  /// fires.
  static Future<void> _initPush(ProviderContainer container) async {
    if (!await FirebaseBootstrap.ensureInitialized()) return;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FcmService.initialize(
        onNotificationTap: appRouter.push,
        onTokenRefresh: (_) => container
            .read(riderAuthProvider.notifier)
            .registerDeviceToken(),
      );
    } catch (e, s) {
      appLogger.e('[Bootstrap] FCM init failed', error: e, stackTrace: s);
    }
  }

  static Future<void> _initLocation(ProviderContainer container) async {
    try {
      await container.read(riderLocationProvider.notifier).refresh();
    } catch (e, s) {
      appLogger.e('[Bootstrap] location init failed', error: e, stackTrace: s);
    }
  }

  /// A session restored from secure storage at startup never passes through
  /// `_persist`, so it registers its token here. A *fresh* login/signup
  /// registers its own from `RiderAuthNotifier._persist`.
  static Future<void> _registerTokenIfSessionRestored(
    ProviderContainer container,
  ) async {
    if (!sl<UserSessionManager>().isLoggedIn) return;
    try {
      await container.read(riderAuthProvider.notifier).registerDeviceToken();
    } catch (e, s) {
      appLogger.e('[Bootstrap] device token registration failed',
          error: e, stackTrace: s);
    }
  }

  /// A session restored from secure storage at cold start has no
  /// login/register call to hang this off (unlike a fresh sign-in — see
  /// `RiderAuthNotifier._persist`), so it's connected here instead.
  static Future<void> _initRealtime() async {
    if (!sl<UserSessionManager>().isLoggedIn) return;
    try {
      await sl<RealtimeService>().connect();
    } catch (e, s) {
      appLogger.e('[Bootstrap] realtime connect failed', error: e, stackTrace: s);
    }
  }
}
