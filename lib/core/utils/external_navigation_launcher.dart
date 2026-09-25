import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

import 'package:delivery_boy/core/services/navigation_return_notifier.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';

/// Hands a destination off to whatever turn-by-turn navigation app the rider
/// already has — Google Maps' own universal link opens the native app when
/// installed and falls back to the browser otherwise, on both platforms.
///
/// Deliberately the *only* navigation this app provides: no in-app
/// turn-by-turn, no route recalculation, no voice guidance — a rider already
/// trusts Google Maps for that, and duplicating it here would be slower to
/// build and worse to use.
class ExternalNavigationLauncher {
  ExternalNavigationLauncher._();

  /// [latitude]/[longitude] give Google Maps an exact pin; [address] alone
  /// still works — Maps geocodes free-text destinations itself — so a point
  /// that failed to resolve on the in-app map can still be navigated to.
  static Future<bool> launch({
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final destination = (latitude != null && longitude != null)
        ? '$latitude,$longitude'
        : address;
    if (destination == null || destination.isEmpty) return false;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${Uri.encodeComponent(destination)}'
      '&travelmode=driving',
    );

    try {
      if (!await canLaunchUrl(uri)) return false;
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Fire-and-forget: a delayed/failed return-prompt must never hold up
      // reporting whether navigation itself launched.
      if (launched) {
        unawaited(NavigationReturnNotifier.show(
          destinationLabel: (address != null && address.isNotEmpty)
              ? address
              : 'your destination',
        ));
      }

      return launched;
    } catch (e, s) {
      appLogger.e('[Navigation] launch failed', error: e, stackTrace: s);
      return false;
    }
  }
}
