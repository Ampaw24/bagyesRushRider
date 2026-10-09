import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/core/services/rider_location_service.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';

/// The location checks a rider must pass before going online.
///
/// Customers only see a rider, and dispatch only reaches them, while their
/// location keeps flowing with the app minimized — which needs "Allow all the
/// time" (Android) / "Always" (iOS) and GPS switched on. Rather than letting a
/// rider appear online while silently sharing nothing, going online is refused
/// until both are in place.
class RiderOnlineLocationGate {
  RiderOnlineLocationGate._();

  /// Walks the rider through whatever is missing. Returns true only when they
  /// may go online.
  static Future<bool> ensure(BuildContext context) async {
    if (!await RiderLocationService.ensureServiceEnabled()) {
      if (!context.mounted) return false;
      final open = await _confirm(
        context,
        title: 'Turn On Location',
        subtitle: 'Location is switched off on this phone. Turn it on so '
            'customers can see you and nearby orders can reach you.',
        confirmText: 'Open Settings',
      );
      if (open) await RiderLocationService.openLocationSettings();
      return false;
    }

    if (await RiderLocationService.hasAlwaysPermission()) return true;
    if (!context.mounted) return false;

    final proceed = await _confirm(
      context,
      title: 'Stay Visible While Online',
      subtitle: 'To receive orders, BagyesRIDER needs your location even '
          'when the app is closed or in the background. On the next screen, '
          "choose 'Allow all the time'.",
      confirmText: 'Continue',
    );
    if (!proceed) return false;

    final result = await RiderLocationService.ensureAlwaysPermission();
    if (result == RiderLocationPermission.granted) return true;
    if (!context.mounted) return false;

    final openSettings = await _confirm(
      context,
      title: "'Allow All The Time' Needed",
      subtitle: "You can't go online without it, so customers can find you "
          "and your deliveries stay tracked. Open Settings, tap Location, "
          "and choose 'Allow all the time'.",
      confirmText: 'Open Settings',
    );
    if (openSettings) await RiderLocationService.openAppSettings();
    return false;
  }

  /// Explains why a rider who was online has been taken offline (or, mid
  /// delivery, warned) after "Always" location was withdrawn.
  static Future<void> showPermissionLost(BuildContext context) async {
    final openSettings = await _confirm(
      context,
      title: 'Location Access Changed',
      subtitle: "BagyesRIDER no longer has 'Allow all the time' location, so "
          "customers can't see you while the app is in the background. "
          'Restore it in Settings to go online.',
      confirmText: 'Open Settings',
      cancelText: 'Later',
    );
    if (openSettings) await RiderLocationService.openAppSettings();
  }

  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String confirmText,
    String cancelText = 'Not Now',
  }) {
    final answer = Completer<bool>();
    CustomDialog.showConfirmation(
      context: context,
      title: title,
      subtitle: subtitle,
      icon: HugeIcons.strokeRoundedLocation01,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: () => answer.complete(true),
      onCancel: () {
        if (!answer.isCompleted) answer.complete(false);
      },
    );
    return answer.future;
  }
}
