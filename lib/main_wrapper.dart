import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/realtime/realtime_service.dart';
import 'package:delivery_boy/core/router/app_router.dart';
import 'package:delivery_boy/core/services/fcm_service.dart';
import 'package:delivery_boy/core/services/firebase_bootstrap.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BagyesRushApp extends ConsumerStatefulWidget {
  const BagyesRushApp({super.key});

  @override
  ConsumerState<BagyesRushApp> createState() => _BagyesRushAppState();
}

class _BagyesRushAppState extends ConsumerState<BagyesRushApp>
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

  /// The spec calls for re-checking the realtime connection on app resume
  /// (host/port/key could have changed, or the socket may have been torn
  /// down while backgrounded) — `ensureConnected` is a cheap no-op when
  /// already connected.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && sl<UserSessionManager>().isLoggedIn) {
      sl<RealtimeService>().ensureConnected();
      _syncPush();
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
      title: 'BagyesRIDER',
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
