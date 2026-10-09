import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/rider_online_intent.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/utils/network_utility.dart'
    show sessionRevision;
import 'package:delivery_boy/features/rider/chat/providers/rider_chat_list_providers.dart';
import 'package:delivery_boy/features/rider/kyc/providers/kyc_providers.dart';
import 'package:delivery_boy/features/rider/notifications/providers/rider_notifications_providers.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/report/providers/rider_my_reports_providers.dart';
import 'package:delivery_boy/features/rider/tracking/providers/rider_presence_providers.dart';
import 'package:delivery_boy/features/rider/tracking/providers/rider_tracking_providers.dart';
import 'package:delivery_boy/features/rider/wallet/providers/rider_me_wallet_providers.dart';
import 'package:delivery_boy/features/rider/wallet/providers/rider_me_wallet_transactions_providers.dart';

/// Resets every piece of per-rider Riverpod state whenever the session
/// ends — logout, account deletion, or a 401 clearing it out of band.
///
/// The root `ProviderContainer` lives for the whole process and these
/// providers aren't autoDispose, so without this the next rider to sign in
/// on the device would briefly see the previous rider's profile, orders and
/// wallet, and GPS would keep pinging `/rider/me/location` with no token.
///
/// Logout and account deletion call [reset] themselves, since they own the
/// navigation that follows. The 401 path has no `Ref`, so [attach] covers
/// it by listening to [sessionRevision].
class RiderSessionTeardown {
  RiderSessionTeardown._();

  static void attach(ProviderContainer container) {
    sessionRevision.addListener(() {
      if (!sl<UserSessionManager>().isLoggedIn) reset(container.invalidate);
    });
  }

  /// [invalidate] is `container.invalidate` or `ref.invalidate`.
  static void reset(void Function(ProviderOrFamily) invalidate) {
    // Invalidation runs each notifier's onDispose immediately: tracking
    // stops its GPS stream and drops buffered pings, and orders drops its
    // realtime order channels. Derived providers (online state, KYC status,
    // tracking mode) recompute from these on their own.
    unawaited(RiderOnlineIntent.clear());
    for (final provider in <ProviderOrFamily>[
      riderTrackingProvider,
      riderPresenceProvider,
      riderMeProfileProvider,
      riderMeOffersProvider,
      riderMeOrdersProvider,
      riderMeOrderHistoryProvider,
      riderMeWalletProvider,
      riderMeWalletTransactionsProvider,
      riderNotificationsProvider,
      riderChatListProvider,
      riderMyReportsProvider,
      kycUploadsProvider,
      kycActionsProvider,
    ]) {
      invalidate(provider);
    }
  }
}
