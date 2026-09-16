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
    final size = MediaQuery.of(context).size;
    // Standard, icon-like footprint — proportional across phones, tablets
    // and landscape without ever dominating the screen.
    final logoSize = (size.shortestSide * 0.22).clamp(80.0, 160.0);

    return Scaffold(
      backgroundColor: kDecorativeBackgroundColor,
      body: DecorativeBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
            child: Column(
              children: [
                const Spacer(flex: 5),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
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
                SizedBox(height: size.height * 0.025),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: size.width * 0.1,
                    height: size.height * 0.0035,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.018),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'FAST · RELIABLE · QUALITY',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: size.width * 0.032,
                        color: greyColor.withValues(alpha: 0.85),
                        letterSpacing: size.width * 0.006,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 6),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: size.width * 0.08,
                    height: size.width * 0.08,
                    child: CircularProgressIndicator(
                      strokeWidth: size.width * 0.006,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      _versionLabel ?? '',
                      style: TextStyle(
                        fontSize: size.width * 0.03,
                        color: greyColor.withValues(alpha: 0.6),
                        letterSpacing: 0.5,
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
