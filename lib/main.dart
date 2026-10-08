import 'dart:async';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/rider_app_bootstrap.dart';
import 'package:delivery_boy/core/services/rider_session_teardown.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:delivery_boy/main_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Guards against an unhandled-exception gap in pusher_client_socket: its
  // private-channel auth call runs inside an un-await0ed async method with
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
    RiderSessionTeardown.attach(container);

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

