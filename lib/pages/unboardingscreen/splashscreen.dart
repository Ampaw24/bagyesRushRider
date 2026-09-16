import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/constant/asset_images.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App entry splash — mirrors the native launch screen (plain white
/// background, centered logo) so the handoff from OS splash to first
/// Flutter frame reads as one continuous screen, then plays a short,
/// staggered brand intro before routing to onboarding or the dashboard.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _taglineFade;
  late final Animation<double> _loaderFade;

  static const _introDuration = Duration(milliseconds: 1800);
  static const _holdDuration = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _controller.forward();
    _navigateToNextScreen();
  }

  void _setupAnimations() {
    _controller = AnimationController(vsync: this, duration: _introDuration);

    // Logo settles in first with a soft scale + fade.
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    // Tagline and loader trail in after the logo, keeping the sequence
    // unhurried.
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
    );
    _loaderFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(_introDuration + _holdDuration);
    if (!mounted) return;

    final isAuthenticated = sl<UserSessionManager>().isLoggedIn;
    if (!mounted) return;

    context.go(isAuthenticated ? AppRoutes.dashboard : AppRoutes.intro);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Logo scales off the narrower screen dimension so it stays proportional
    // on phones, tablets, foldables and in landscape — sized to a standard,
    // icon-like footprint rather than filling the screen.
    final logoSize = size.shortestSide * 0.2;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(logoSize * 0.22),
                      child: Image.asset(
                        AssetImages.bagyesLogo,
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.045),
                FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    'FAST · RELIABLE · QUALITY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size.width * 0.032,
                      color: AppColors.textSecondary,
                      letterSpacing: size.width * 0.008,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.07),
                FadeTransition(
                  opacity: _loaderFade,
                  child: SizedBox(
                    width: size.width * 0.08,
                    height: size.width * 0.08,
                    child: CircularProgressIndicator(
                      strokeWidth: size.width * 0.005,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
