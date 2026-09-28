import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/realtime/realtime_service.dart';
import 'package:delivery_boy/core/router/app_router.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:flutter/material.dart';

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
