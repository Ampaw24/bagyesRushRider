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
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';
import 'package:delivery_boy/core/widgets/sos_floating_button.dart';
import 'package:delivery_boy/features/rider/notifications/providers/rider_notifications_providers.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_orders_providers.dart';
import 'package:delivery_boy/features/rider/home/views/screens/rider_home_screen.dart';
import 'package:delivery_boy/features/rider/orders/views/screens/rider_new_orders_screen.dart';
import 'package:delivery_boy/features/rider/orders/views/screens/rider_active_orders_screen.dart';
import 'package:delivery_boy/features/rider/orders/views/screens/rider_order_history_screen.dart';
import 'package:delivery_boy/features/rider/wallet/views/screens/rider_wallet_screen.dart';
import 'package:delivery_boy/features/rider/profile/views/screens/rider_profile_screen.dart';
import 'package:hugeicons/hugeicons.dart';

/// Provider for online/offline queue toggle state
final riderQueueProvider = StateProvider<bool>((ref) {
  final user = sl<UserSessionManager>().currentUser;
  return user?['queue'] as bool? ?? false;
});

/// Tracks whether the rider dismissed the KYC reminder banner this session.
final kycBannerDismissedProvider = StateProvider<bool>((ref) {
  return sl<SharedPreferences>().getBool('kyc_banner_dismissed') ?? false;
});

KycStatus _currentKycStatus() {
  final userData = sl<UserSessionManager>().currentUser;
  if (userData == null) return KycStatus.notStarted;
  switch (userData['kycStatus'] as String?) {
    case 'approved':
      return KycStatus.approved;
    case 'pendingReview':
      return KycStatus.pendingReview;
    case 'rejected':
      return KycStatus.rejected;
    default:
      return KycStatus.notStarted;
  }
}

class RiderDashboardScreen extends ConsumerStatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  ConsumerState<RiderDashboardScreen> createState() =>
      _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends ConsumerState<RiderDashboardScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderNotificationsProvider.notifier).load();
    });
  }

  Future<void> _toggleQueue() async {
    try {
      final session = sl<UserSessionManager>();
      final user = session.currentUser;
      if (user == null) return;

      final currentQueue = ref.read(riderQueueProvider);
      // Block going online if KYC is not approved
      if (!currentQueue && _currentKycStatus() != KycStatus.approved) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete identity verification to go online'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final newQueue = !currentQueue;

      ref.read(riderQueueProvider.notifier).state = newQueue;
      HapticFeedback.lightImpact();

      final updatedUser = Map<String, dynamic>.from(user)
        ..['queue'] = newQueue;
      await session.saveSession(
        token: session.token!,
        user: updatedUser,
      );
    } catch (_) {
      ref.read(riderQueueProvider.notifier).state =
          !ref.read(riderQueueProvider);
    }
  }

  void _goToOrders() => setState(() => _currentIndex = 1);
  void _goToWallet() => setState(() => _currentIndex = 2);

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(riderQueueProvider);
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
  const NavItem({required this.icon, required this.label});
}

const _navItems = [
  NavItem(icon: HugeIcons.strokeRoundedHome01,        label: 'Home'),
  NavItem(icon: HugeIcons.strokeRoundedDeliveryBox01, label: 'Orders'),
  NavItem(icon: HugeIcons.strokeRoundedWallet01,      label: 'Wallet'),
  NavItem(icon: HugeIcons.strokeRoundedUser,          label: 'Profile'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Floating frosted-glass navigation bar
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
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
                          child: HugeIcon(
                            icon: items[i].icon,
                            size: w * 0.06,
                            color: selected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
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
        ref.watch(activeOrdersProvider).orders.isNotEmpty;

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
    final kycStatus = _currentKycStatus();
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
