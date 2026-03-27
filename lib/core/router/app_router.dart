import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/router/app_routes.dart';

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
// ── Auth model ────────────────────────────────────────────────────────────────
import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final session = sl<UserSessionManager>();
      final isLoggedIn = session.isLoggedIn;
      final location = state.matchedLocation;

      // TODO: Re-enable public route check + auth guard once API is integrated.
      // final isPublicRoute = location == AppRoutes.splash ||
      //     location == AppRoutes.intro ||
      //     location == AppRoutes.login ||
      //     location == AppRoutes.signup ||
      //     location == AppRoutes.otp ||
      //     location == AppRoutes.vehicleInfo ||
      //     location == AppRoutes.vehicleDetails ||
      //     location == AppRoutes.forgotPassword;
      // if (!isLoggedIn && !isPublicRoute) return AppRoutes.login;

      // Authenticated user landing on intro (e.g. back-press) → skip to app
      if (isLoggedIn && location == AppRoutes.intro) {
        final userData = session.currentUser;
        if (userData != null) {
          final user = RiderUserModel.fromJson(userData);
          if (!user.isProfileComplete) return AppRoutes.onboarding;
        }
        return AppRoutes.dashboard;
      }

      // Unauthenticated user trying to reach a protected screen
      // TODO: Re-enable auth guard once API is integrated.
      // if (!isLoggedIn && !isPublicRoute) return AppRoutes.login;

      // Splash is always allowed — SplashScreen itself drives navigation
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
        pageBuilder: (_, state) =>
            _slideRight(state, const RiderSignupScreen()),
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
