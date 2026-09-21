import 'dart:async';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/realtime/realtime_service.dart';
import 'package:delivery_boy/core/router/app_router.dart';
import 'package:delivery_boy/core/services/rider_app_bootstrap.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Guards against an unhandled-exception gap in pusher_client_socket: its
  // private-channel auth call runs inside an un-awaited async method with
  // no try/catch, so a network hiccup during a channel subscribe throws
  // into this zone instead of anywhere Realtime­Service can catch it.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load(fileName: '.env');

    await initServiceLocator();
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    // Owned explicitly so the launch bootstrap can push results — the
    // location fix, device-token registration — into the same Riverpod
    // graph the widget tree reads from. Never disposed: this is the root
    // container.
    final container = ProviderContainer();

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const BagyesRushApp(),
      ),
    );

    // Fire-and-forget: permission dialogs, the first GPS fix and push
    // registration must not gate the first frame. Firebase is initialized in
    // here too, so a missing config file degrades to "no push" rather than a
    // failure to boot.
    unawaited(RiderAppBootstrap.run(container));
  }, (error, stackTrace) {
    appLogger.e('[Zone] uncaught error', error: error, stackTrace: stackTrace);
  });
}

class BagyesRushApp extends StatefulWidget {
  const BagyesRushApp({super.key});

  @override
  State<BagyesRushApp> createState() => _BagyesRushAppState();
}

class _BagyesRushAppState extends State<BagyesRushApp> with WidgetsBindingObserver {
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
