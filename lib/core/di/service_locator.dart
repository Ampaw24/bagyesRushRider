import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/utils/network_utility.dart';
// Phase 2: Auth
import 'package:delivery_boy/features/rider/auth/repositories/rider_auth_repository.dart';
import 'package:delivery_boy/features/rider/auth/repositories/rider_auth_repository_impl.dart';
import 'package:delivery_boy/features/rider/auth/services/rider_auth_api_service.dart';
// Phase 3: Orders
import 'package:delivery_boy/features/rider/orders/repositories/rider_orders_repository.dart';
import 'package:delivery_boy/features/rider/orders/repositories/rider_orders_repository_impl.dart';
import 'package:delivery_boy/features/rider/orders/services/rider_orders_api_service.dart';
// Phase 5: Wallet
import 'package:delivery_boy/features/rider/wallet/repositories/rider_wallet_repository.dart';
import 'package:delivery_boy/features/rider/wallet/repositories/rider_wallet_repository_impl.dart';
import 'package:delivery_boy/features/rider/wallet/services/rider_wallet_api_service.dart';
// Phase 6: Profile
import 'package:delivery_boy/features/rider/profile/repositories/rider_profile_repository.dart';
import 'package:delivery_boy/features/rider/profile/repositories/rider_profile_repository_impl.dart';
import 'package:delivery_boy/features/rider/profile/services/rider_profile_api_service.dart';
// Phase 7: Tracking
import 'package:delivery_boy/features/rider/tracking/repositories/rider_tracking_repository.dart';
import 'package:delivery_boy/features/rider/tracking/repositories/rider_tracking_repository_impl.dart';
import 'package:delivery_boy/features/rider/tracking/services/rider_tracking_api_service.dart';
// Notifications
import 'package:delivery_boy/features/rider/notifications/repositories/rider_notifications_repository.dart';
import 'package:delivery_boy/features/rider/notifications/repositories/rider_notifications_repository_impl.dart';
import 'package:delivery_boy/features/rider/notifications/services/rider_notifications_api_service.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // ── External ────────────────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  // ── Core ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<UserSessionManager>(
    () => UserSessionManager(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<Dio>(
    () => NetworkUtility.createDio(sl<UserSessionManager>()),
  );

  // ── Rider Auth ──────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => RiderAuthApiService(sl<Dio>()));
  sl.registerLazySingleton<RiderAuthRepository>(
    () => RiderAuthRepositoryImpl(sl<RiderAuthApiService>()),
  );

  // ── Rider Orders ────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => RiderOrdersApiService(sl<Dio>()));
  sl.registerLazySingleton<RiderOrdersRepository>(
    () => RiderOrdersRepositoryImpl(sl<RiderOrdersApiService>()),
  );

  // ── Rider Wallet ────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => RiderWalletApiService(sl<Dio>()));
  sl.registerLazySingleton<RiderWalletRepository>(
    () => RiderWalletRepositoryImpl(sl<RiderWalletApiService>()),
  );

  // ── Rider Profile ───────────────────────────────────────────────────────
  sl.registerLazySingleton(() => RiderProfileApiService(sl<Dio>()));
  sl.registerLazySingleton<RiderProfileRepository>(
    () => RiderProfileRepositoryImpl(sl<RiderProfileApiService>()),
  );

  // ── Rider Tracking ──────────────────────────────────────────────────────
  sl.registerLazySingleton(() => RiderTrackingApiService(sl<Dio>()));
  sl.registerLazySingleton<RiderTrackingRepository>(
    () => RiderTrackingRepositoryImpl(sl<RiderTrackingApiService>()),
  );

  // ── Rider Notifications ──────────────────────────────────────────────────
  sl.registerLazySingleton(() => RiderNotificationsApiService(sl<Dio>()));
  sl.registerLazySingleton<RiderNotificationsRepository>(
    () => RiderNotificationsRepositoryImpl(sl<RiderNotificationsApiService>()),
  );
}
