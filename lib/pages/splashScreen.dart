import 'dart:math' as math;

import 'package:delivery_boy/constant/asset_images.dart';
import 'package:delivery_boy/constant/colors.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../components/widget/decorative.widget.dart' hide kDecorativeBackgroundColor;

/// App entry splash — decorative motif background behind the logo card.
/// Rendered at [AppRoutes.splash] via `core/router/app_router.dart`.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

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
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _versionLabel = 'v${info.version}');
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDecorativeBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // Card is clamped so it stays comfortable on both small phones
          // and large tablets, while still scaling with the viewport.
          final cardSize =
              (math.min(width, height) * 0.34).clamp(120.0, 260.0);
          final loaderWidth = (width * 0.32).clamp(96.0, 220.0);

          return DecorativeBackground(
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(cardSize * 0.22),
                        child: Image.asset(
                          AssetImages.bagyesLogo,
                          width: cardSize,
                          height: cardSize,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: Container(
                        width: 40,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 18,
                        left: 24,
                        right: 24,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'FAST · RELIABLE · QUALITY',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            color: greyColor.withValues(alpha: 0.8),
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 6),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: loaderWidth,
                      height: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 20),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        _versionLabel ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: greyColor.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
