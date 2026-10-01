import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:delivery_boy/core/services/fcm_service.dart';
import 'package:delivery_boy/core/services/firebase_bootstrap.dart';
import 'package:delivery_boy/core/services/rider_location_service.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';

/// Makes sure a signed-in rider has notifications on — they're how new
/// order offers arrive, so a rider with them off silently misses work.
///
/// * Never asked yet → shows the OS prompt.
/// * Previously denied → iOS won't show the OS prompt again, so this
///   explains why it matters and offers a shortcut to the Settings app.
///
/// Asks at most once per app session, so a rider who taps "Not now" isn't
/// nagged on every visit to the home screen.
class NotificationPermissionPrompt {
  NotificationPermissionPrompt._();

  static bool _shownThisSession = false;

  static Future<void> maybeShow(BuildContext context) async {
    if (_shownThisSession || !FirebaseBootstrap.isAvailable) return;

    final status = await FcmService.refreshPermission();
    if (!context.mounted) return;

    switch (status) {
      case AuthorizationStatus.notDetermined:
        _shownThisSession = true;
        await FcmService.ensurePermission();
      case AuthorizationStatus.denied:
        _shownThisSession = true;
        // Android reports an unanswered or once-dismissed prompt as
        // `denied` too, and still lets it be shown — only send the rider to
        // Settings once the OS itself refuses to ask again.
        if (defaultTargetPlatform == TargetPlatform.android &&
            FcmService.isPermitted(await FcmService.ensurePermission())) {
          return;
        }
        if (!context.mounted) return;
        await CustomDialog.showConfirmation(
          context: context,
          title: 'Turn on notifications',
          subtitle: "Notifications are how new delivery requests reach you. "
              "With them off you'll miss orders while the app is closed. "
              'Open Settings → Notifications and allow them for BagyesRIDER.',
          confirmText: 'Open Settings',
          cancelText: 'Not now',
          onConfirm: RiderLocationService.openAppSettings,
        );
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        break;
    }
  }
}
