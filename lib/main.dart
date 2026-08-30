import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/router/app_router.dart';
import 'package:delivery_boy/states/app.state.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;

/// Must be a top-level function to run in an isolate when the app is
/// terminated or in the background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background messages are displayed automatically by FCM on Android.
  // No additional handling needed here for basic use.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase must be initialized before anything else
  // await Firebase.initializeApp();
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await initServiceLocator();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(
    ProviderScope(
      // MultiProvider kept until all old pages are deleted
      child: legacy.MultiProvider(
        providers: [legacy.ChangeNotifierProvider(create: (_) => AppState())],
        child: const BagyesRushApp(),
      ),
    ),
  );
}

/// Built once. Constructing a GoRouter inside `build()` would hand
/// MaterialApp a fresh router on every rebuild, discarding navigation state.
final _appRouter = createAppRouter();

class BagyesRushApp extends StatelessWidget {
  const BagyesRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Delivery Boy',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      routerConfig: _appRouter,
    );
  }
}
