import 'dart:async';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/router/app_router.dart';
import 'package:delivery_boy/core/services/rider_app_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await initServiceLocator();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // Owned explicitly so the launch bootstrap can push results — the location
  // fix, device-token registration — into the same Riverpod graph the widget
  // tree reads from. Never disposed: this is the root container.
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
}

class BagyesRushApp extends StatelessWidget {
  const BagyesRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BagyesRush Rider',
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
