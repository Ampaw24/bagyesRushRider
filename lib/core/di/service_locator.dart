import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/utils/network_utility.dart';
// Phase 2: Auth
import 'package:delivery_boy/features/rider/auth/repositories/rider_auth_repository.dart';
import 'package:delivery_boy/features/rider/auth/repositories/rider_auth_repository_impl.dart';
import 'package:delivery_boy/features/rider/auth/services/rider_auth_api_service.dart';
// Rider "Me" API (/rider/me/* — see the "v1 / rider" Postman collection)
import 'package:delivery_boy/features/rider/profile/services/rider_me_profile_api_service.dart';
import 'package:delivery_boy/features/rider/profile/repositories/rider_me_profile_repository.dart';
import 'package:delivery_boy/features/rider/profile/repositories/rider_me_profile_repository_impl.dart';
import 'package:delivery_boy/features/rider/orders/services/rider_me_order_api_service.dart';
import 'package:delivery_boy/features/rider/orders/repositories/rider_me_order_repository.dart';
import 'package:delivery_boy/features/rider/orders/repositories/rider_me_order_repository_impl.dart';
import 'package:delivery_boy/features/rider/wallet/services/rider_me_wallet_api_service.dart';
import 'package:delivery_boy/features/rider/wallet/repositories/rider_me_wallet_repository.dart';
import 'package:delivery_boy/features/rider/wallet/repositories/rider_me_wallet_repository_impl.dart';
// Vehicle catalogue (public reads — signup wizard's Type/Make/Model picker)
import 'package:delivery_boy/features/rider/vehicles/service/rider_vehicle_catalog_api_service.dart';
import 'package:delivery_boy/features/rider/vehicles/repository/vehicle_catalog_repository.dart';
import 'package:delivery_boy/features/rider/vehicles/repository/vehicle_catalog_repository_impl.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // ── External ────────────────────────────────────────────────────────────
  // SharedPreferences still backs non-auth device prefs (settings, dashboard
  // banners, notification read-state) — the session itself lives in secure
  // storage below.
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());

  // ── Core ────────────────────────────────────────────────────────────────
  // Built eagerly (not registerLazySingleton) and hydrated up front: the Dio
  // interceptor below reads UserSessionManager.token synchronously on every
  // request, and secure storage has no sync read API.
  final sessionManager = UserSessionManager(sl<FlutterSecureStorage>());
  await sessionManager.load();
  sl.registerLazySingleton<UserSessionManager>(() => sessionManager);
  sl.registerLazySingleton<Dio>(
    () => NetworkUtility.createDio(sl<UserSessionManager>()),
  );

  // ── Rider Auth ──────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => RiderAuthApiService(sl<Dio>()));
  sl.registerLazySingleton<RiderAuthRepository>(
    () => RiderAuthRepositoryImpl(sl<RiderAuthApiService>()),
  );

  // ── Rider "Me" API (/rider/me/* — see the "v1 / rider" Postman collection) ──────────
  sl.registerLazySingleton(() => RiderMeProfileApiService(sl<Dio>()));
  sl.registerLazySingleton<RiderMeProfileRepository>(
    () => RiderMeProfileRepositoryImpl(sl<RiderMeProfileApiService>()),
  );

  sl.registerLazySingleton(() => RiderMeOrderApiService(sl<Dio>()));
  sl.registerLazySingleton<RiderMeOrderRepository>(
    () => RiderMeOrderRepositoryImpl(sl<RiderMeOrderApiService>()),
  );

  sl.registerLazySingleton(() => RiderMeWalletApiService(sl<Dio>()));
  sl.registerLazySingleton<RiderMeWalletRepository>(
    () => RiderMeWalletRepositoryImpl(sl<RiderMeWalletApiService>()),
  );

  // ── Vehicle Catalogue ───────────────────────────────────────────────────
  sl.registerLazySingleton(() => RiderVehicleCatalogApiService(sl<Dio>()));
  sl.registerLazySingleton<VehicleCatalogRepository>(
    () => VehicleCatalogRepositoryImpl(sl<RiderVehicleCatalogApiService>()),
  );
}
