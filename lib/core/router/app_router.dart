import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

// ── Screen imports ── added as each feature module is created ──────────────
// Phase 2: Auth
import 'package:delivery_boy/features/rider/auth/views/screens/rider_login_screen.dart';
import 'package:delivery_boy/features/rider/auth/views/screens/rider_signup_screen.dart';
import 'package:delivery_boy/features/rider/auth/views/screens/rider_otp_screen.dart';
// Phase 4: Dashboard
import 'package:delivery_boy/features/rider/dashboard/views/screens/rider_dashboard_screen.dart';
// Phase 6: Profile
// import 'package:delivery_boy/features/rider/profile/views/screens/rider_edit_profile_screen.dart';
// Phase 7: Tracking
import 'package:delivery_boy/features/rider/tracking/views/screens/rider_map_screen.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final session = sl<UserSessionManager>();
      final isLoggedIn = session.isLoggedIn;

      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.otp ||
          state.matchedLocation == AppRoutes.splash;

      // Not logged in and trying to access protected route → send to login
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;

      // Logged in and on splash → send to dashboard
      if (isLoggedIn && state.matchedLocation == AppRoutes.splash) {
        return AppRoutes.dashboard;
      }

      // Not logged in on splash → send to login
      if (!isLoggedIn && state.matchedLocation == AppRoutes.splash) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      // ── Splash ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const _SplashScreen(),
      ),

      // ── Auth ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const RiderLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (_, __) => const RiderSignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (_, state) => RiderOtpScreen(
          credentials: (state.extra as Map<String, dynamic>?) ?? {},
        ),
      ),

      // ── Dashboard (shell with nested routes) ────────────────────────────
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (_, __) => const RiderDashboardScreen(),
        routes: [
          GoRoute(
            path: 'map',
            builder: (_, __) => const RiderMapScreen(),
          ),
          GoRoute(
            path: 'profile/edit',
            builder: (_, __) =>
                const _PlaceholderScreen(title: 'Edit Profile'),
          ),
          GoRoute(
            path: 'notifications',
            builder: (_, __) =>
                const _PlaceholderScreen(title: 'Notifications'),
          ),
        ],
      ),
    ],
  );
}

// ── Temporary splash widget ──────────────────────────────────────────────────
// GoRouter redirect handles the actual navigation; this just shows a spinner.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/delivery_boy.jpg',
              width: 200,
              fit: BoxFit.fitWidth,
            ),
            const SizedBox(height: 40),
            SpinKitPulse(color: primaryColor, size: 50),
          ],
        ),
      ),
    );
  }
}

// ── Temporary placeholder screen ─────────────────────────────────────────────
// Used while a feature screen is not yet migrated.
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: Text(
          '$title — coming soon',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
