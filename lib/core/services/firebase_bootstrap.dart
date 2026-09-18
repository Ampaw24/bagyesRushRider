import 'package:firebase_core/firebase_core.dart';

import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:delivery_boy/firebase_options.dart';

/// Brings Firebase up once, and records whether it actually came up.
///
/// Push is a best-effort feature: a checkout missing `google-services.json` /
/// `GoogleService-Info.plist`, a misconfigured Firebase project, or an iOS
/// Simulator without APNs must still leave the app bootable and the location
/// features fully working. Every Firebase-touching call site therefore checks
/// [isAvailable] before doing anything, rather than assuming init succeeded.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  /// True once [ensureInitialized] has actually brought Firebase up.
  static bool isAvailable = false;

  static Future<bool> ensureInitialized() async {
    if (isAvailable) return true;

    try {
      // Explicit options rather than bare initializeApp(): this works even
      // where the native config file is missing from the platform bundle,
      // and it fails loudly rather than half-initializing.
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isAvailable = true;
      appLogger.i('[Firebase] initialized');
    } catch (e, s) {
      appLogger.w('[Firebase] unavailable — push notifications disabled: $e');
      appLogger.d('$s');
      isAvailable = false;
    }

    return isAvailable;
  }
}
