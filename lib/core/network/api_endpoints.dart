/// Account roles accepted by `POST /register`.
///
/// Verified against the live backend — an invalid value returns
/// `Role must be one of: customer, vendor, rider`.
abstract final class AuthRoles {
  static const rider = 'rider';
}

/// `purpose` values accepted by [ApiEndpoints.otpVerify].
///
/// Verified against the live backend — an unknown value returns
/// `That is not a purpose a code can be requested for`.
abstract final class OtpPurposes {
  static const accountRecovery = 'account_recovery';
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

  /// Purpose-scoped code check. Body: `{phone, code, purpose}`.
  /// Confirms a [passwordForgot] code (purpose [OtpPurposes.accountRecovery])
  /// before the rider picks a new password — the same step the customer and
  /// vendor app takes. [passwordReset] re-validates the code, so it is still
  /// sent there. Distinct from [phoneVerify], which marks a signed-up
  /// account's phone as verified.
  static const otpVerify = '/otp/verify';

  /// Changes the signed-in user's password using their current one —
  /// distinct from the OTP-based [passwordForgot]/[passwordReset] pair.
  /// Requires Bearer auth. Body:
  /// `{current_password, password, password_confirmation}`.
  /// Verified live: returns 401 (not 404) without a valid token, confirming
  /// the route exists on this backend.
  static const passwordChange = '/password/change';

  /// Permanently deletes the signed-in user's account. Requires Bearer
  /// auth. Body: `{password (required), reason (optional, max:500)}`.
  static const accountDelete = '/account/delete';

  // NOTE: this backend has no /auth/refresh-token route (verified: 404).
  // A refresh token is persisted when returned, but cannot be redeemed yet.

  // ── Push notifications ──────────────────────────────────────────────────
  /// FCM device registration, shared verbatim with the customer and vendor
  /// apps on this same Laravel v1 backend — the route is role-agnostic and
  /// associates the device with whoever the Bearer token belongs to.
  ///
  /// `POST` body: `{token, platform, device_name}` (the key is `token`, not
  /// `device_token`). Accepts 200 or 201. `DELETE` takes no body and
  /// deregisters the calling device.
  static const deviceToken = '/device-tokens';

  // ── Vehicle catalogue (public reads — no auth required) ─────────────────────
  // Cascading reference data for the rider signup vehicle picker:
  // type -> make (filtered by vehicle_type_id) -> model (filtered by
  // vehicle_make_id). Admin CRUD counterparts exist under /admin/vehicle-*
  // but are not needed by this app.
  static const vehicleTypes = '/vehicle-types';
  static const vehicleMakes = '/vehicle-makes';
  static const vehicleModels = '/vehicle-models';

  /// Public list of bank and mobile-money payout providers, split by
  /// `type` (`bank` | `mobile_money`).
  static const payoutProviders = '/payout-providers';

  /// Public, unauthenticated home-screen banners — shared verbatim with the
  /// customer/vendor app on this backend. Verified live 2026-09-19: returns
  /// `{data: {items: [{id, title, subtitle, description, image_url,
  /// placement, display_order, link: {type, value}}], pagination: {...}}}`.
  /// Every banner seen so far has `placement: "home"` — there is no distinct
  /// rider-specific placement value on this backend.
  static const banners = '/banners';

  // ── Realtime (WebSocket) ─────────────────────────────────────────────────
  /// Bearer-authenticated. Returns the Reverb/Pusher connection details
  /// (host, port, key, `auth_endpoint`, channel-name templates) — never
  /// hardcode those, they come from here so they can differ per
  /// environment. See `RealtimeService`.
  static const realtimeConfig = '/realtime/config';

  // ── Chat / Conversations ─────────────────────────────────────────────────
  /// `GET /conversations` — the one shared, role-agnostic folder: customer,
  /// vendor and rider apps all call these same paths, the server resolves
  /// who's asking from the bearer token. Never build a role-prefixed variant
  /// (mirrors the customer/vendor app's own `chat-apis.md` contract).
  static const conversations = '/conversations';

  /// `GET /conversations/:id`
  static String conversationById(int id) => '$conversations/$id';

  /// `GET /conversations/:id/messages?per_page=&cursor=` (cursor pagination
  /// — response envelope has a `cursor: {next, previous, has_more}`, not
  /// `page`/`total`) | `POST /conversations/:id/messages`
  static String conversationMessages(int id) => '$conversations/$id/messages';

  /// `POST /conversations/:id/read` — no body.
  static String conversationRead(int id) => '$conversations/$id/read';

  /// `POST /conversations/:id/typing` — no body, fire-and-forget.
  static String conversationTyping(int id) => '$conversations/$id/typing';

  /// `GET /orders/:id/conversation` — `id` is the **order** id, not a
  /// conversation id. Returns the same payload shape as [conversationById].
  /// 422 before a rider is assigned — see `ConversationUnavailableFailure`.
  static String orderConversation(int orderId) =>
      '/orders/$orderId/conversation';

  // ── In-app notifications ────────────────────────────────────────────────
  /// Role-agnostic inbox, shared verbatim with the customer/vendor app
  /// (confirmed live 2026-09-19: returns 401, not 404, unauthenticated —
  /// route exists and requires Bearer auth). Response:
  /// `{data: {items: [{id, type, title, body, data, is_read, read_at,
  /// created_at}], pagination: {...}}}`. Optional query params on the list
  /// endpoint: `unread` (bool), `per_page` (int) — unused here, this app
  /// loads the unfiltered first page.
  static const notifications = '/notifications';
  static const notificationsReadAll = '/notifications/read-all';
  static String notificationById(String id) => '/notifications/$id';
  static String notificationRead(String id) => '/notifications/$id/read';

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

  // ── Rider Me: Reports ────────────────────────────────────────────────────
  /// Mirrors the customer/vendor app's "Report a Problem" feature
  /// (`/customer/reports`, `/vendor/me/reports`) at the `/rider/me/*` path
  /// this app already uses for every other rider-scoped resource. The
  /// customer/vendor contract has no rider-as-reporter role documented, so
  /// this path is unverified against a live response — built ahead of
  /// backend confirmation the same way other `/rider/me/*` additions have
  /// been (see rider-me-migration notes). Same request/response shape:
  /// `multipart/form-data` submit, `{target_type, order_id?, target_name,
  /// target_phone?, reason_code, reason_label, description, attachments[]}`.
  static const riderMeReports = '/rider/me/reports';
  static String riderMeReport(int id) => '$riderMeReports/$id';

  /// `GET /reports/reasons` — role-agnostic, shared verbatim with the
  /// customer/vendor app (every reporter role calls this same path;
  /// the reference app's own constant name, `customerReportReasons`,
  /// is misleading). Returns reasons grouped by target type, e.g.
  /// `{vendor: [...], customer: [...], order_issue: [...], general: [...]}`.
  static const reportReasons = '/reports/reasons';
}
