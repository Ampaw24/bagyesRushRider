/// Account roles accepted by `POST /register`.
///
/// Verified against the live backend — an invalid value returns
/// `Role must be one of: customer, vendor, rider`.
abstract final class AuthRoles {
  static const rider = 'rider';
}

abstract final class ApiEndpoints {
  // ═══════════════════════════════════════════════════════════════════════
  // Auth — role-agnostic Laravel v1. The same endpoints serve customer,
  // vendor and rider accounts; only the `role` sent to /register differs.
  // ═══════════════════════════════════════════════════════════════════════
  static const register = '/register';
  static const login = '/login';
  static const logout = '/logout';
  static const profile = '/profile';

  /// Phone verification for a signed-up account. Body: `{phone}`.
  static const phoneSendCode = '/phone/send-code';

  /// Body: `{phone, code}` — the key is `code`, not `otp`.
  static const phoneVerify = '/phone/verify';

  /// Public entry point for the forgot-password flow. Body: `{phone}`.
  /// Distinct from [phoneSendCode] — do not substitute one for the other.
  static const passwordForgot = '/password/forgot';

  /// Body: `{phone, code, password, password_confirmation}`.
  static const passwordReset = '/password/reset';

  /// Changes the signed-in user's password using their current one —
  /// distinct from the OTP-based [passwordForgot]/[passwordReset] pair.
  /// Requires Bearer auth. Body:
  /// `{current_password, password, password_confirmation}`.
  /// Verified live: returns 401 (not 404) without a valid token, confirming
  /// the route exists on this backend.
  static const passwordChange = '/password/change';

  // NOTE: this backend has no /auth/refresh-token route (verified: 404).
  // A refresh token is persisted when returned, but cannot be redeemed yet.

  // ── Vehicle catalogue (public reads — no auth required) ─────────────────────
  // Cascading reference data for the rider signup vehicle picker:
  // type -> make (filtered by vehicle_type_id) -> model (filtered by
  // vehicle_make_id). Admin CRUD counterparts exist under /admin/vehicle-*
  // but are not needed by this app.
  static const vehicleTypes = '/vehicle-types';
  static const vehicleMakes = '/vehicle-makes';
  static const vehicleModels = '/vehicle-models';

  // ═══════════════════════════════════════════════════════════════════════
  // Rider "Me" API — /rider/me/*
  // Laravel v1 backend, Bearer auth, restricted to the `rider` role.
  // Source: Postman collection "v1 / rider" (profile, order, wallet).
  // ═══════════════════════════════════════════════════════════════════════

  // ── Rider Me: Profile ────────────────────────────────────────────────────
  static const riderMe = '/rider/me';
  static const riderMeAgreement = '/rider/me/agreement';
  static const riderMeAvailability = '/rider/me/availability';
  static String riderMeDocument(String type) => '/rider/me/documents/$type';
  static const riderMeLocation = '/rider/me/location';
  static const riderMeLocationBatch = '/rider/me/location/batch';
  static const riderMePayout = '/rider/me/payout';
  static const riderMePhoto = '/rider/me/photo';
  static const riderMeSubmitReview = '/rider/me/submit-review';

  // ── Rider Me: Orders ──────────────────────────────────────────────────────
  static const riderMeOffers = '/rider/me/offers';
  static String riderMeOfferAccept(int id) => '/rider/me/offers/$id/accept';
  static String riderMeOfferDecline(int id) => '/rider/me/offers/$id/decline';
  static const riderMeOrders = '/rider/me/orders';
  static String riderMeOrder(int id) => '/rider/me/orders/$id';
  static String riderMeOrderArrivedAtPickup(int id) =>
      '/rider/me/orders/$id/arrived-at-pickup';
  static String riderMeOrderPickUp(int id) => '/rider/me/orders/$id/pick-up';
  static String riderMeOrderArrivedAtDropoff(int id) =>
      '/rider/me/orders/$id/arrived-at-dropoff';
  static String riderMeOrderDeliver(int id) => '/rider/me/orders/$id/deliver';
  static String riderMeOrderRelease(int id) => '/rider/me/orders/$id/release';
  static String riderMeOrderUnreachable(int id) =>
      '/rider/me/orders/$id/unreachable';
  static String riderMeOrderStopArrived(int id, int stopId) =>
      '/rider/me/orders/$id/stops/$stopId/arrived';
  static String riderMeOrderStopDeliver(int id, int stopId) =>
      '/rider/me/orders/$id/stops/$stopId/deliver';
  static String riderMeOrderStopFail(int id, int stopId) =>
      '/rider/me/orders/$id/stops/$stopId/fail';

  // ── Rider Me: Wallet ──────────────────────────────────────────────────────
  static const riderMeWallet = '/rider/me/wallet';
  static const riderMeWalletTransactions = '/rider/me/wallet/transactions';
  static const riderMeWithdrawals = '/rider/me/withdrawals';
  static String riderMeWithdrawalCancel(int id) =>
      '/rider/me/withdrawals/$id/cancel';
}
