import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/orders/views/screens/rider_new_orders_screen.dart';
import 'package:delivery_boy/features/rider/orders/views/screens/rider_active_orders_screen.dart';
import 'package:delivery_boy/features/rider/orders/views/screens/rider_order_history_screen.dart';
import 'package:delivery_boy/features/rider/wallet/views/screens/rider_wallet_screen.dart';
import 'package:delivery_boy/features/rider/profile/views/screens/rider_profile_screen.dart';

/// Provider for online/offline queue toggle state
final riderQueueProvider = StateProvider<bool>((ref) {
  final user = sl<UserSessionManager>().currentUser;
  return user?['queue'] as bool? ?? false;
});

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkProfile());
  }

  void _checkProfile() {
    final user = sl<UserSessionManager>().currentUser;
    if (user == null) return;
    final incomplete = user['name'] == null ||
        user['email'] == null ||
        user['licenceBack'] == null ||
        user['licenceFront'] == null ||
        user['motorIssurance'] == null ||
        user['roadWorthy'] == null ||
        user['numberPlate'] == null ||
        user['selfie'] == null;
    if (incomplete && mounted) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) context.go(AppRoutes.editProfile);
      });
    }
  }

  Future<void> _toggleQueue() async {
    try {
      final session = sl<UserSessionManager>();
      final user = session.currentUser;
      if (user == null) return;

      final currentQueue = ref.read(riderQueueProvider);
      final newQueue = !currentQueue;

      // Optimistically update UI
      ref.read(riderQueueProvider.notifier).state = newQueue;

      // Update backend via DI — using the profile repository once available.
      // For now, update via profile provider which has updateCourier.
      // (Will be wired properly in Phase 6)

      // Update local session cache to reflect queue change
      final updatedUser = Map<String, dynamic>.from(user)
        ..['queue'] = newQueue;
      await session.saveSession(
        token: session.token!,
        user: updatedUser,
      );
    } catch (_) {
      // Revert on error
      ref.read(riderQueueProvider.notifier).state =
          !ref.read(riderQueueProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(riderQueueProvider);

    final tabs = [
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
            textColor: whiteColor,
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        bottomNavigationBar: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
          child: BottomNavigationBar(
            backgroundColor: whiteColor,
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            elevation: 8,
            selectedItemColor: primaryColor,
            unselectedItemColor: greyColor,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.local_mall),
                label: 'Order',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet),
                label: 'Wallet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
      ),
    );
  }
}

/// Orders tab — wraps the 3-tab order view with the online toggle in the AppBar
class _OrdersTab extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onToggle;

  const _OrdersTab({required this.isOnline, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: scaffoldBgColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: whiteColor,
          title: Text('Bagyes Rush', style: bigHeadingStyle),
          actions: [
            IconButton(
              icon: isOnline
                  ? const Icon(Icons.toggle_on, color: Colors.green)
                  : Icon(Icons.toggle_off, color: blackColor),
              onPressed: onToggle,
            ),
          ],
          bottom: TabBar(
            unselectedLabelColor: Colors.grey.withValues(alpha: 0.3),
            labelColor: primaryColor,
            indicatorColor: primaryColor,
            tabs: const [
              Tab(text: 'New'),
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RiderNewOrdersScreen(),
            RiderActiveOrdersScreen(),
            RiderOrderHistoryScreen(),
          ],
        ),
      ),
    );
  }
}
