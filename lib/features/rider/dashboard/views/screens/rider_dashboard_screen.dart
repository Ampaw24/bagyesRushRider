import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/services/navigation_return_notifier.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';
import 'package:delivery_boy/core/widgets/sos_floating_button.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/features/rider/notifications/providers/rider_notifications_providers.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_avatar_providers.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/shared_widgets/rider_avatar.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/tracking/providers/rider_tracking_providers.dart';
import 'package:delivery_boy/features/rider/home/views/screens/rider_home_screen.dart';
import 'package:delivery_boy/features/rider/orders/views/screens/rider_new_orders_screen.dart';
import 'package:delivery_boy/features/rider/orders/views/screens/rider_active_orders_screen.dart';
import 'package:delivery_boy/features/rider/orders/views/screens/rider_order_history_screen.dart';
import 'package:delivery_boy/features/rider/wallet/views/screens/rider_wallet_screen.dart';
import 'package:delivery_boy/features/rider/profile/views/screens/rider_profile_screen.dart';
import 'package:hugeicons/hugeicons.dart';

/// Online/offline state, sourced from `GET /rider/me`'s `is_online`.
final riderQueueProvider = Provider<bool>((ref) {
  return ref.watch(riderMeProfileProvider).profile?.isOnline ?? false;
});

/// Tracks whether the rider dismissed the KYC reminder banner this session.
final kycBannerDismissedProvider = StateProvider<bool>((ref) {
  return sl<SharedPreferences>().getBool('kyc_banner_dismissed') ?? false;
});

/// Maps `/rider/me`'s `verification_status` onto the local [KycStatus].
///
/// Deliberately permissive about the wire vocabulary — anything
/// unrecognised falls back to [KycStatus.notStarted] rather than
/// mis-reporting a rider as verified.
KycStatus kycStatusFrom(String? raw) {
  switch (raw) {
    case 'approved':
    case 'verified':
      return KycStatus.approved;
    case 'pendingReview':
    case 'pending_review':
    case 'under_review':
    case 'pending':
    case 'submitted':
      return KycStatus.pendingReview;
    case 'rejected':
    case 'declined':
      return KycStatus.rejected;
    default:
      return KycStatus.notStarted;
  }
}

/// Current verification status from `/rider/me`, falling back to the local
/// echo in the session until the profile has loaded.
///
/// `pending_review` is reported from registration onwards — before the
/// profile is even complete — so it only reads as "under review" once the
/// server says nothing is left to fill in.
final riderKycStatusProvider = Provider<KycStatus>((ref) {
  final profile = ref.watch(riderMeProfileProvider.select((s) => s.profile));
  if (profile == null) {
    return kycStatusFrom(
      sl<UserSessionManager>().currentUser?['kycStatus'] as String?,
    );
  }
  if (profile.canGoOnline) return KycStatus.approved;

  final status = kycStatusFrom(profile.status);
  if (status == KycStatus.approved || status == KycStatus.rejected) {
    return status;
  }
  return profile.isProfileComplete
      ? KycStatus.pendingReview
      : KycStatus.notStarted;
});

class RiderDashboardScreen extends ConsumerStatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  ConsumerState<RiderDashboardScreen> createState() =>
      _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends ConsumerState<RiderDashboardScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderNotificationsProvider.notifier).load();
      // Populates is_online + verification_status for this screen.
      ref.read(riderMeProfileProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Covers every way the rider actually comes back — tapping the return
    // notification, switching apps manually, or Maps closing on its own —
    // not just a notification tap, which a `didChangeAppLifecycleState`
    // check can't distinguish from any other reason the app resumed anyway.
    if (state == AppLifecycleState.resumed) {
      NavigationReturnNotifier.cancel();
    }
  }

  Future<void> _toggleQueue() async {
    final currentQueue = ref.read(riderQueueProvider);

    // The server's own gate (`can_go_online`) decides; the local status is
    // only a fallback until /rider/me has loaded.
    final profile = ref.read(riderMeProfileProvider).profile;
    final canGoOnline = profile?.canGoOnline ??
        ref.read(riderKycStatusProvider) == KycStatus.approved;
    if (!currentQueue && !canGoOnline) {
      _explainOnlineBlock();
      return;
    }

    HapticFeedback.lightImpact();

    // setAvailability patches profile.isOnline only once the server
    // confirms, so riderQueueProvider follows it without extra bookkeeping
    // and a failed toggle simply leaves the previous state showing.
    final ok = await ref
        .read(riderMeProfileProvider.notifier)
        .setAvailability(!currentQueue);

    if (!ok && mounted) {
      CustomDialog.showError(
        context: context,
        title: 'Status Not Updated',
        subtitle: ref.read(riderMeProfileProvider).actionMessage ??
            'Could not update your availability. Please try again.',
      );
    }
  }

  /// Tells the rider why they can't go online, with a way to fix it.
  void _explainOnlineBlock() {
    final kycStatus = ref.read(riderKycStatusProvider);
    if (kycStatus == KycStatus.pendingReview) {
      CustomDialog.showInfo(
        context: context,
        title: 'Under Review',
        subtitle: "Your profile is with our team. You'll be able to go "
            'online as soon as it is approved.',
      );
      return;
    }
    CustomDialog.showConfirmation(
      context: context,
      title: kycStatus == KycStatus.rejected
          ? 'Changes Needed'
          : 'Finish Verification',
      subtitle: kycStatus == KycStatus.rejected
          ? 'Update your profile and submit it again to go online.'
          : 'Complete your profile so we can verify you. Your progress is '
              'saved as you go.',
      confirmText: 'Continue',
      cancelText: 'Later',
      onConfirm: () {
        if (mounted) context.push(AppRoutes.kyc);
      },
    );
  }

  void _goToOrders() => setState(() => _currentIndex = 1);
  void _goToWallet() => setState(() => _currentIndex = 2);
  void _goToProfile() => setState(() => _currentIndex = 3);

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(riderQueueProvider);

    // Starts/stops the GPS ping loop centrally — this shell stays mounted
    // across tabs, so it's the right place to react regardless of which
    // tab the rider is on. Gated on shouldTrackLocationProvider (true once
    // any order is past pickup), not on individual delivery actions, so it
    // stays correct with more than one concurrent active order.
    ref.listen<bool>(shouldTrackLocationProvider, (_, shouldTrack) {
      final tracking = ref.read(riderTrackingProvider.notifier);
      if (shouldTrack) {
        tracking.startTracking();
      } else {
        tracking.stopTracking();
      }
    });

    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    // Content bottom padding = inner bar height + its bottom margin
    // inner: vertical padding w*0.03*2 + icon w*0.06 + gap w*0.015 + dot w*0.013
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final navInnerHeight = w * 0.03 * 2 + w * 0.06 + w * 0.015 + w * 0.013;
    final navBottomMargin = viewPadding.bottom + w * 0.04;
    final contentPadBottom = navInnerHeight + navBottomMargin;

    final tabs = [
      RiderHomeScreen(
        onToggleQueue: _toggleQueue,
        onViewAllOrders: _goToOrders,
        onViewWallet: _goToWallet,
        onViewProfile: _goToProfile,
      ),
      _OrdersTab(isOnline: isOnline, onToggle: _toggleQueue),
      const RiderWalletScreen(),
      const RiderProfileScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          Fluttertoast.showToast(
            msg: 'Press Back Once Again to Exit.',
            backgroundColor: Colors.black,
            textColor: Colors.white,
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Stack(
          children: [
            // ── Tab content — pad bottom so nothing hides under the bar ──
            MediaQuery(
              data: mq.copyWith(
                padding: mq.padding.copyWith(bottom: contentPadBottom),
              ),
              child: IndexedStack(
                index: _currentIndex,
                children: tabs,
              ),
            ),

            // ── Floating nav bar ───────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _FloatingNavBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
                items: _navItems,
                avatarUrl: ref.watch(riderAvatarUrlProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NavItem model
// ─────────────────────────────────────────────────────────────────────────────

class NavItem {
  final IconData icon;
  final String label;

  /// Shows the rider's photo in place of [icon] when they have one.
  final bool showsAvatar;

  const NavItem({
    required this.icon,
    required this.label,
    this.showsAvatar = false,
  });
}

const _navItems = [
  NavItem(icon: HugeIcons.strokeRoundedHome01,        label: 'Home'),
  NavItem(icon: HugeIcons.strokeRoundedDeliveryBox01, label: 'Orders'),
  NavItem(icon: HugeIcons.strokeRoundedWallet01,      label: 'Wallet'),
  NavItem(
    icon: HugeIcons.strokeRoundedUser,
    label: 'Profile',
    showsAvatar: true,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Floating frosted-glass navigation bar
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;
  final String? avatarUrl;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      margin: EdgeInsets.only(
        left: w * 0.06,
        right: w * 0.06,
        bottom: bottomPad + w * 0.04,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(w * 0.08),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000), // black @ 15%
            blurRadius: 20,
            spreadRadius: 0,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(w * 0.08),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.02,
              vertical: w * 0.03,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(w * 0.08),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final selected = i == currentIndex;
                final iconColor = selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.45);
                final photoUrl = items[i].showsAvatar ? avatarUrl : null;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: SizedBox(
                    width: w * 0.14,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon with animated scale
                        AnimatedScale(
                          scale: selected ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: photoUrl != null
                              ? _NavAvatar(
                                  url: photoUrl,
                                  fallbackIcon: items[i].icon,
                                  size: w * 0.06,
                                  color: iconColor,
                                )
                              : HugeIcon(
                                  icon: items[i].icon,
                                  size: w * 0.06,
                                  color: iconColor,
                                ),
                        ),
                        SizedBox(height: w * 0.015),
                        // Dot indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          height: w * 0.013,
                          width: selected ? w * 0.013 : 0,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// A nav tab's photo, ringed in the tab's current colour so selection reads
/// the same as on the glyph tabs. Falls back to [fallbackIcon] if the photo
/// fails to load.
class _NavAvatar extends StatelessWidget {
  final String url;
  final IconData fallbackIcon;
  final double size;
  final Color color;

  const _NavAvatar({
    required this.url,
    required this.fallbackIcon,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ring = size * 0.08;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: ring),
      ),
      child: RiderAvatar(
        radius: size / 2 - ring,
        imageUrl: url,
        backgroundColor: Colors.transparent,
        placeholder: HugeIcon(
          icon: fallbackIcon,
          size: size * 0.7,
          color: color,
        ),
      ),
    );
  }
}

/// Orders tab — wraps the 3-tab order view with the online toggle + bell in AppBar
class _OrdersTab extends ConsumerWidget {
  final bool isOnline;
  final VoidCallback onToggle;

  const _OrdersTab({required this.isOnline, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount =
        ref.watch(riderNotificationsProvider).unreadCount;
    final hasActiveOrders =
        ref.watch(riderMeOrdersProvider).orders.isNotEmpty;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        floatingActionButton: hasActiveOrders
            ? const SosFloatingButton()
            : null,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 20,
          title: const Text(
            'Bagyes Rush',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            // Order chats
            IconButton(
              icon: const Icon(HugeIcons.strokeRoundedBubbleChat,
                  color: AppColors.textPrimary, size: 24),
              onPressed: () => context.push(AppRoutes.chat),
            ),
            // Notifications bell with unread badge
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(HugeIcons.strokeRoundedNotification01,
                      color: AppColors.textPrimary, size: 26),
                  onPressed: () =>
                      context.push(AppRoutes.notifications),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Animated online/offline pill
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin:
                    const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppColors.success.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOnline
                        ? AppColors.success.withValues(alpha: 0.4)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulseAnimation(
                      active: isOnline,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              isOnline ? AppColors.success : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        isOnline ? 'Online' : 'Offline',
                        key: ValueKey(isOnline),
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOnline
                              ? AppColors.success
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          bottom: TabBar(
            unselectedLabelColor: Colors.grey.shade400,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'New'),
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: Column(
          children: [
            _KycBanner(),
            const Expanded(
              child: TabBarView(
                children: [
                  RiderNewOrdersScreen(),
                  RiderActiveOrdersScreen(),
                  RiderOrderHistoryScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pulse animation widget — looping ScaleTransition 0.9 ↔ 1.1 when active
class _PulseAnimation extends StatefulWidget {
  final bool active;
  final Widget child;

  const _PulseAnimation({required this.active, required this.child});

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.active) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulseAnimation old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      if (widget.active) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.stop();
        _ctrl.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// KYC status banner shown above the orders tab until KYC is approved.
class _KycBanner extends ConsumerWidget {
  const _KycBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kycStatus = ref.watch(riderKycStatusProvider);
    final dismissed = ref.watch(kycBannerDismissedProvider);

    if (kycStatus == KycStatus.approved) return const SizedBox.shrink();
    if (dismissed && kycStatus != KycStatus.pendingReview) {
      return const SizedBox.shrink();
    }

    final isPending = kycStatus == KycStatus.pendingReview;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isPending
              ? Colors.blue.shade50
              : Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPending
                ? Colors.blue.shade200
                : Colors.amber.shade300,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isPending
                  ? HugeIcons.strokeRoundedHourglass
                  : HugeIcons.strokeRoundedUserCheck01,
              size: 18,
              color: isPending
                  ? Colors.blue.shade600
                  : Colors.amber.shade700,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPending
                        ? 'Verification Under Review'
                        : kycStatus == KycStatus.rejected
                            ? 'Verification Rejected — Resubmit'
                            : 'Complete Identity Verification',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isPending
                          ? Colors.blue.shade800
                          : Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPending
                        ? 'Your documents are being reviewed. You\'ll be notified once approved.'
                        : kycStatus == KycStatus.rejected
                            ? 'Your submission was rejected. Please review and resubmit your documents.'
                            : 'Verify your identity to start accepting delivery orders.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      color: isPending
                          ? Colors.blue.shade700
                          : Colors.amber.shade800,
                    ),
                  ),
                  if (!isPending) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.kyc),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              kycStatus == KycStatus.rejected
                                  ? 'Resubmit'
                                  : 'Start Verification',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            ref
                                .read(kycBannerDismissedProvider.notifier)
                                .state = true;
                            final prefs = sl<SharedPreferences>();
                            await prefs.setBool(
                                'kyc_banner_dismissed', true);
                          },
                          child: Text(
                            'Later',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
