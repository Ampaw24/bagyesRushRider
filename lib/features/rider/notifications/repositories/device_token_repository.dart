import 'package:delivery_boy/constant/typedef.dart';

/// Registers and deregisters this device's FCM token with the backend.
abstract class DeviceTokenRepository {
  /// Associates [token] with the currently authenticated rider.
  ResultFuture<void> register({
    required String token,
    required String platform,
    required String deviceName,
  });

  /// Deregisters the calling device's [token]. Must run while the session's
  /// Bearer token is still valid — see `RiderAuthNotifier.logout`.
  ResultFuture<void> unregister({required String token});
}
