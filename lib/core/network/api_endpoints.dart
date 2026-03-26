abstract final class ApiEndpoints {
  // ── Auth ─────────────────────────────────────────────────────────────────
  static const riderLogin = '/couriers/login';
  static const riderSignup = '/couriers/signup';
  static const sendOtp = '/otp/send';

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

  // ── Password Reset ────────────────────────────────────────────────────────
  // Re-uses sendOtp for the OTP step; then PUT /couriers/update for the new password.
  static const resetPassword = '/couriers/update';

  // ── KYC ───────────────────────────────────────────────────────────────────
  static const submitKyc = '/couriers/kyc/submit';
  static String getKycStatus(String id) => '/couriers/kyc/$id';
  static const uploadKycDoc = '/couriers/kyc/upload';
}
