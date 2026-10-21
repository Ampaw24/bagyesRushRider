import 'package:gopady_rider/constant/app_theme.dart';
import 'package:gopady_rider/constant/app_tokens.dart';
import 'package:gopady_rider/constant/baseurl.dart';
import 'package:gopady_rider/core/di/service_locator.dart';
import 'package:gopady_rider/core/router/app_routes.dart';
import 'package:gopady_rider/core/services/fcm_service.dart';
import 'package:gopady_rider/core/services/user_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gopady_rider/core/widgets/brand_pattern_background.dart';
import 'package:gopady_rider/core/widgets/gopady_logo.dart';
import 'package:gopady_rider/core/widgets/skyline_watermark.dart';

/// App entry splash — GoPady lockup over the brand-green pattern and skyline.
/// Rendered at [AppRoutes.splash] via `core/router/app_router.dart`.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  String? _versionLabel;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadVersion();
    _navigateToNextScreen();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: AppMotion.intro,
    )..forward();
  }

  Future<void> _loadVersion() async {
    try {
      //final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _versionLabel = 'v${kAppVersion}');
    } catch (_) {
      // Non-critical: the version label simply stays hidden if unavailable.
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final isLoggedIn = sl<UserSessionManager>().isLoggedIn;
    if (!mounted) return;

    context.go(isLoggedIn ? AppRoutes.dashboard : AppRoutes.intro);

    // A notification that launched the app from terminated parks its route
    // on FcmService (there is no navigator yet when getInitialMessage
    // resolves). Drain it now that the base route is settled — but only for
    // a signed-in rider, since every push target lives behind /dashboard.
    final pending = FcmService.pendingRoute;
    FcmService.pendingRoute = null;
    if (pending != null && isLoggedIn && mounted) {
      context.push(pending);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Everything scales off the shorter side so portrait, landscape and
          // split-screen all keep the same proportions.
          final unit = constraints.biggest.shortestSide;

          return Stack(
            children: [
              Positioned.fill(
                child: BrandReveal(
                  animation: _animationController,
                  end: 0.5,
                  child: const BrandPatternBackground(),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: BrandReveal(
                  animation: _animationController,
                  begin: 0.1,
                  end: 0.65,
                  slideFrom: const Offset(0, 0.25),
                  child: const SkylineWatermark(color: AppColors.primaryDark),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandReveal(
                        animation: _animationController,
                        begin: 0.2,
                        end: 0.8,
                        scaleFrom: 0.9,
                        slideFrom: const Offset(0, 0.08),
                        blurFrom: unit * 0.025,
                        child: GoPadyLogo(
                          width: unit * 0.72,
                          variant: GoPadyLogoVariant.onDark,
                        ),
                      ),
                      SizedBox(height: unit * 0.04),
                      BrandReveal(
                        animation: _animationController,
                        begin: 0.5,
                        end: 0.9,
                        child: Text(
                          'RIDER',
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: unit * 0.045,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                            letterSpacing: unit * 0.02,
                          ),
                        ),
                      ),
                      SizedBox(height: unit * 0.08),
                      BrandReveal(
                        animation: _animationController,
                        begin: 0.7,
                        end: 1,
                        child: SizedBox(
                          width: unit * 0.3,
                          height: unit * 0.008,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(unit * 0.004),
                            child: const LinearProgressIndicator(
                              backgroundColor: AppColors.primaryDark,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: unit * 0.04),
                      Text(
                        _versionLabel ?? '',
                        style: TextStyle(
                          fontSize: unit * 0.03,
                          color: AppColors.onDarkMuted,
                          letterSpacing: unit * 0.001,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
