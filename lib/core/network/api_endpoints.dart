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

  // NOTE: this backend has no /auth/refresh-token route (verified: 404).
  // A refresh token is persisted when returned, but cannot be redeemed yet.

  // ── Profile ───────────────────────────────────────────────────────────────
  static String riderProfile(String id) => '/couriers/details/$id';
  static const updateCourier = '/couriers/update';
  static const uploadDoc = '/couriers/upload/doc';

  // ── Orders ────────────────────────────────────────────────────────────────
  static const getOrders = '/orders/get';
  static String getRequested(String id) => '/orders/requested/$id';
  static String getActiveOrders(String id) => '/orders/active/$id';
  static const acceptOrder = '/orders/accept';
  static const rejectOrder = '/orders/reject';
  static const updateOrder = '/orders/update';
  static const setTrip = '/orders/trip/set';
  static const finishTrip = '/orders/trip/finish';
  static const updateLocation = '/orders/location/update';

  // ── Wallet / Earnings ─────────────────────────────────────────────────────
  static String getEarnings(String id) => '/earnings/user/$id';

  // ── History ───────────────────────────────────────────────────────────────
  static String getHistory(String id) => '/orders/history/$id';

  // ── Notifications ─────────────────────────────────────────────────────────
  static String getNotifications(String id) => '/notifications/user/$id';

  // ── KYC ───────────────────────────────────────────────────────────────────
  static const submitKyc = '/couriers/kyc/submit';
  static String getKycStatus(String id) => '/couriers/kyc/$id';
  static const uploadKycDoc = '/couriers/kyc/upload';

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
  static String riderMeOrderDeliver(int id) => '/rider/me/orders/$id/deliver';
  static String riderMeOrderRelease(int id) => '/rider/me/orders/$id/release';
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
