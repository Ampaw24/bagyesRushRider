import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_boy/core/realtime/realtime_service.dart';
import 'package:delivery_boy/core/realtime/services/realtime_config_api_service.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/utils/network_utility.dart';
// Phase 2: Auth
import 'package:delivery_boy/features/rider/auth/repositories/rider_auth_repository.dart';
import 'package:delivery_boy/features/rider/auth/repositories/rider_auth_repository_impl.dart';
import 'package:delivery_boy/features/rider/auth/services/rider_auth_api_service.dart';
// Push / device tokens (shared /device-tokens route)
import 'package:delivery_boy/features/rider/notifications/services/device_token_api_service.dart';
import 'package:delivery_boy/features/rider/notifications/repositories/device_token_repository.dart';
import 'package:delivery_boy/features/rider/notifications/repositories/device_token_repository_impl.dart';
// In-app notification inbox (shared /notifications route)
import 'package:delivery_boy/features/rider/notifications/services/rider_notification_api_service.dart';
import 'package:delivery_boy/features/rider/notifications/repositories/rider_notification_repository.dart';
import 'package:delivery_boy/features/rider/notifications/repositories/rider_notification_repository_impl.dart';
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
import 'package:delivery_boy/features/rider/report/services/rider_report_api_service.dart';
import 'package:delivery_boy/features/rider/report/repositories/rider_report_repository.dart';
import 'package:delivery_boy/features/rider/report/repositories/rider_report_repository_impl.dart';
// Legal documents (public /rider-agreement)
import 'package:delivery_boy/features/rider/legal/services/legal_document_api_service.dart';
import 'package:delivery_boy/features/rider/legal/repositories/legal_document_repository.dart';
import 'package:delivery_boy/features/rider/legal/repositories/legal_document_repository_impl.dart';
import 'package:delivery_boy/features/rider/home/services/rider_banner_api_service.dart';
import 'package:delivery_boy/features/rider/home/repositories/rider_banner_repository.dart';
import 'package:delivery_boy/features/rider/home/repositories/rider_banner_repository_impl.dart';
// Vehicle catalogue (public reads — signup wizard's Type/Make/Model picker)
import 'package:delivery_boy/features/rider/vehicles/service/rider_vehicle_catalog_api_service.dart';
import 'package:delivery_boy/features/rider/vehicles/repository/vehicle_catalog_repository.dart';
import 'package:delivery_boy/features/rider/vehicles/repository/vehicle_catalog_repository_impl.dart';
// Chat (shared /conversations API — see chat-apis.md)
import 'package:delivery_boy/features/rider/chat/services/rider_chat_api_service.dart';
import 'package:delivery_boy/features/rider/chat/repositories/rider_chat_repository.dart';
import 'package:delivery_boy/features/rider/chat/repositories/rider_chat_repository_impl.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // ── External ────────────────────────────────────────────────────────────
  // SharedPreferences still backs non-auth device prefs (settings, dashboard
  // banners, notification read-state) — the session itself lives in secure
  // storage below.
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage());

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

  // ── Realtime (WebSocket) ────────────────────────────────────────────────
  sl.registerLazySingleton(() => RealtimeConfigApiService(sl<Dio>()));
  sl.registerLazySingleton(
    () => RealtimeService(
        sl<RealtimeConfigApiService>(), sl<UserSessionManager>()),
  );

  // ── Rider Auth ──────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => RiderAuthApiService(sl<Dio>()));
  sl.registerLazySingleton<RiderAuthRepository>(
    () => RiderAuthRepositoryImpl(sl<RiderAuthApiService>()),
  );

  // ── Push / device tokens ────────────────────────────────────────────────
  // Shared `/device-tokens` route — same contract as the customer app.
  sl.registerLazySingleton(() => DeviceTokenApiService(sl<Dio>()));
  sl.registerLazySingleton<DeviceTokenRepository>(
    () => DeviceTokenRepositoryImpl(sl<DeviceTokenApiService>()),
  );

  // ── In-app notification inbox ───────────────────────────────────────────
  // Shared `/notifications` route — same contract as the customer app.
  sl.registerLazySingleton(() => RiderNotificationApiService(sl<Dio>()));
  sl.registerLazySingleton<RiderNotificationRepository>(
    () => RiderNotificationRepositoryImpl(sl<RiderNotificationApiService>()),
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

  sl.registerLazySingleton(() => RiderReportApiService(sl<Dio>()));
  sl.registerLazySingleton<RiderReportRepository>(
    () => RiderReportRepositoryImpl(sl<RiderReportApiService>()),
  );

  sl.registerLazySingleton(() => LegalDocumentApiService(sl<Dio>()));
  sl.registerLazySingleton<LegalDocumentRepository>(
    () => LegalDocumentRepositoryImpl(sl<LegalDocumentApiService>()),
  );

  // ── Home banners (public /banners — shared with the customer/vendor app) ──
  sl.registerLazySingleton(() => RiderBannerApiService(sl<Dio>()));
  sl.registerLazySingleton<RiderBannerRepository>(
    () => RiderBannerRepositoryImpl(sl<RiderBannerApiService>()),
  );

  // ── Vehicle Catalogue ───────────────────────────────────────────────────
  sl.registerLazySingleton(() => RiderVehicleCatalogApiService(sl<Dio>()));
  sl.registerLazySingleton<VehicleCatalogRepository>(
    () => VehicleCatalogRepositoryImpl(sl<RiderVehicleCatalogApiService>()),
  );

  // ── Chat (shared /conversations API) ────────────────────────────────────
  sl.registerLazySingleton(() => RiderChatApiService(sl<Dio>()));
  sl.registerLazySingleton<RiderChatRepository>(
    () => RiderChatRepositoryImpl(sl<RiderChatApiService>()),
  );
}
