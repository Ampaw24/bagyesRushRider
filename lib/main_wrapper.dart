import 'dart:async';

import 'package:gopady_rider/constant/app_theme.dart';
import 'package:gopady_rider/core/di/service_locator.dart';
import 'package:gopady_rider/core/realtime/realtime_service.dart';
import 'package:gopady_rider/core/router/app_router.dart';
import 'package:gopady_rider/core/services/fcm_service.dart';
import 'package:gopady_rider/core/services/firebase_bootstrap.dart';
import 'package:gopady_rider/core/services/user_session_manager.dart';
import 'package:gopady_rider/core/utils/app_logger.dart';
import 'package:gopady_rider/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:gopady_rider/features/rider/tracking/providers/rider_presence_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoPadyRiderApp extends ConsumerStatefulWidget {
  const GoPadyRiderApp({super.key});

  @override
  ConsumerState<GoPadyRiderApp> createState() => _GoPadyRiderAppState();
}

class _GoPadyRiderAppState extends ConsumerState<GoPadyRiderApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// On resume: re-check the realtime connection (host/port/key could have
  /// changed, or the socket may have been torn down while backgrounded —
  /// `ensureConnected` is a cheap no-op when already connected), re-sync push
  /// registration, and re-assert the rider's presence.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && sl<UserSessionManager>().isLoggedIn) {
      sl<RealtimeService>().ensureConnected();
      _syncPush();
      // The app may have been dormant long enough for the server to mark the
      // rider offline, or for the GPS loop to die — see RiderPresenceNotifier.
      unawaited(ref.read(riderPresenceProvider.notifier).sync());
    }
  }

  /// Picks up notifications being switched on in the Settings app, and
  /// retries a token registration that missed its APNs token on launch.
  /// `registerDeviceToken` dedupes, so this is cheap when nothing changed.
  Future<void> _syncPush() async {
    if (!FirebaseBootstrap.isAvailable) return;
    try {
      final status = await FcmService.refreshPermission();
      if (FcmService.isPermitted(status)) {
        await ref.read(riderAuthProvider.notifier).registerDeviceToken();
      }
    } catch (e, s) {
      appLogger.e('[Push] resume sync failed', error: e, stackTrace: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GoPady Rider',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        );
      },
    );
  }
}
