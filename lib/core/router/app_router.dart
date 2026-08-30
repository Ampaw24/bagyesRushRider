import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/utils/network_utility.dart' show sessionRevision;

// ── Splash / Intro ─────────────────────────────────────────────────────────────
import 'package:delivery_boy/pages/unboardingscreen/splashscreen.dart';
import 'package:delivery_boy/pages/unboardingscreen/onboarding_screen.dart';
// ── Auth screens ──────────────────────────────────────────────────────────────
import 'package:delivery_boy/features/rider/auth/views/screens/rider_login_screen.dart';
import 'package:delivery_boy/features/rider/auth/views/screens/rider_signup_screen.dart';
import 'package:delivery_boy/features/rider/auth/views/screens/rider_otp_screen.dart';
import 'package:delivery_boy/features/rider/auth/views/screens/rider_forgot_password_screen.dart';
import 'package:delivery_boy/features/rider/auth/views/screens/rider_vehicle_info_screen.dart';
import 'package:delivery_boy/features/rider/auth/views/screens/rider_vehicle_details_screen.dart';
// ── Dashboard ─────────────────────────────────────────────────────────────────
import 'package:delivery_boy/features/rider/dashboard/views/screens/rider_dashboard_screen.dart';
// ── Profile ───────────────────────────────────────────────────────────────────
import 'package:delivery_boy/features/rider/profile/views/screens/rider_profile_edit_screen.dart';
import 'package:delivery_boy/features/rider/profile/views/screens/rider_document_upload_screen.dart';
// ── Notifications ─────────────────────────────────────────────────────────────
import 'package:delivery_boy/features/rider/notifications/views/screens/rider_notifications_screen.dart';
// ── Settings ──────────────────────────────────────────────────────────────────
import 'package:delivery_boy/features/rider/settings/views/screens/rider_settings_screen.dart';
// ── Onboarding (profile setup stepper) ────────────────────────────────────────
import 'package:delivery_boy/features/rider/onboarding/views/screens/rider_onboarding_screen.dart';
// ── KYC ───────────────────────────────────────────────────────────────────────
import 'package:delivery_boy/features/rider/kyc/views/screens/kyc_screen.dart';
// ── Tracking ──────────────────────────────────────────────────────────────────
import 'package:delivery_boy/features/rider/tracking/views/screens/rider_map_screen.dart';

/// Routes reachable while signed out.
///
/// The whole signup flow is public: registration only fires on the vehicle
/// details screen (the first point at which `POST /register` has every field
/// it requires for a rider), so screens 1-3 always run unauthenticated, and
/// `/otp` may run either side of a token depending on whether registration
/// returned one.
const _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.intro,
  AppRoutes.login,
  AppRoutes.signup,
  AppRoutes.otp,
  AppRoutes.vehicleInfo,
  AppRoutes.vehicleDetails,
  AppRoutes.forgotPassword,
};

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.intro,
    // Re-evaluates the guard when a 401 clears the session mid-session.
    refreshListenable: sessionRevision,
    redirect: (context, state) {
      final isLoggedIn = sl<UserSessionManager>().isLoggedIn;
      final location = state.matchedLocation;

      // Signed in and back on the entry screens → straight into the app.
      // Profile-completeness is no longer gated here: it now depends on
      // GET /rider/me, which this synchronous callback cannot await.
      // The dashboard drives that prompt instead.
      if (isLoggedIn &&
          (location == AppRoutes.intro || location == AppRoutes.splash)) {
        return AppRoutes.dashboard;
      }

      // Signed out and heading somewhere protected.
      if (!isLoggedIn && !_publicRoutes.contains(location)) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      // ── Splash (no transition — it IS the initial frame) ──────────────────
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),

      // ── Intro swipe onboarding — fade up from splash ───────────────────────
      GoRoute(
        path: AppRoutes.intro,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingIntroScreen(),
          transitionDuration: const Duration(milliseconds: 700),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          ),
        ),
      ),

      // ── Auth — slide in from right ─────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, state) => _slideRight(state, const RiderLoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (_, state) => _slideRight(
          state,
          // `extra` carries the form back when registration fails on a later
          // screen for a field typed here, so the rider isn't retyping it.
          RiderSignupScreen(
            prefill: (state.extra as Map<String, dynamic>?) ?? const {},
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.otp,
        pageBuilder: (_, state) => _slideRight(
          state,
          RiderOtpScreen(
            credentials: (state.extra as Map<String, dynamic>?) ?? {},
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.vehicleInfo,
        pageBuilder: (_, state) => _slideRight(
          state,
          RiderVehicleInfoScreen(
            credentials: (state.extra as Map<String, dynamic>?) ?? {},
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.vehicleDetails,
        pageBuilder: (_, state) => _slideRight(
          state,
          RiderVehicleDetailsScreen(
            credentials: (state.extra as Map<String, dynamic>?) ?? {},
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (_, state) =>
            _slideRight(state, const RiderForgotPasswordScreen()),
      ),

      // ── Profile setup onboarding (stepper) — fade ─────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (_, state) => _fade(state, const RiderOnboardingScreen()),
      ),

      // ── Dashboard (shell with nested routes) ──────────────────────────────
      GoRoute(
        path: AppRoutes.dashboard,
        pageBuilder: (_, state) =>
            _fade(state, const RiderDashboardScreen()),
        routes: [
          GoRoute(
            path: 'map',
            pageBuilder: (_, state) =>
                _slideRight(state, const RiderMapScreen()),
          ),
          GoRoute(
            path: 'profile/edit',
            pageBuilder: (_, state) =>
                _slideRight(state, const RiderProfileEditScreen()),
          ),
          GoRoute(
            path: 'profile/documents',
            pageBuilder: (_, state) =>
                _slideRight(state, const RiderDocumentUploadScreen()),
          ),
          GoRoute(
            path: 'notifications',
            pageBuilder: (_, state) =>
                _slideRight(state, const RiderNotificationsScreen()),
          ),
          GoRoute(
            path: 'settings',
            pageBuilder: (_, state) =>
                _slideRight(state, const RiderSettingsScreen()),
          ),
          GoRoute(
            path: 'kyc',
            pageBuilder: (_, state) =>
                _slideRight(state, const KycScreen()),
          ),
        ],
      ),
    ],
  );
}

// ── Shared transition helpers ─────────────────────────────────────────────────

/// Slide in from the right — used for all drill-down screens.
CustomTransitionPage<void> _slideRight(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
  );
}

/// Fade transition — used for top-level screens (dashboard, onboarding).
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 450),
    transitionsBuilder: (_, animation, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}
