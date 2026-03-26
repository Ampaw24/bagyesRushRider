import 'dart:async';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/constant/asset_images.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final sessionManager = sl<UserSessionManager>();
    final isAuthenticated = sessionManager.isLoggedIn;

    if (!mounted) return;

    if (isAuthenticated) {
      context.go(AppRoutes.dashboard);
    } else {
      context.go(AppRoutes.intro);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Badge size: 55% of the narrower dimension so it scales on every screen
    final logoSize = size.shortestSide * 0.35;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo — image fills the rounded badge, no background
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(logoSize * 0.18),
                  child: Image.asset(
                    AssetImages.bagyesLogo,
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            SizedBox(height: size.height * 0.03),

            // Animated App Name
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'bagyesRUSH',
                    style: TextStyle(
                      fontSize: size.width * 0.08,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 2,
                      fontFamily: 'Pacifico',
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Text(
                    'FAST • RELIABLE • QUALITY',
                    style: TextStyle(
                      fontSize: size.width * 0.03,
                      color: Colors.grey[400],
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: size.height * 0.08),

            // Loader
            FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox(
                height: 40,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
