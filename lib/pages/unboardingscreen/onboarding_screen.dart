import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _PageData {
  final String title;
  final String subtitle;
  final IconData mainIcon;
  final Color color;
  final Color accentLight;
  final String badge;
  final IconData badgeIcon;

  const _PageData({
    required this.title,
    required this.subtitle,
    required this.mainIcon,
    required this.color,
    required this.accentLight,
    required this.badge,
    required this.badgeIcon,
  });
}

const _pages = [
  _PageData(
    title: 'Welcome to\nbagyesRUSH',
    subtitle:
        'Join thousands of riders delivering happiness across Ghana. Fast, reliable, and rewarding.',
    mainIcon: Icons.delivery_dining_rounded,
    color: AppColors.primary,
    accentLight: Color(0xFFFFEBEE),
    badge: 'Rider Network',
    badgeIcon: Icons.people_alt_rounded,
  ),
  _PageData(
    title: 'Accept Orders\nInstantly',
    subtitle:
        'Get real-time delivery requests straight to your phone. One tap to accept and start earning.',
    mainIcon: Icons.notifications_active_rounded,
    color: Color(0xFFFF7043),
    accentLight: Color(0xFFFFE0B2),
    badge: 'Real-Time Alerts',
    badgeIcon: Icons.bolt_rounded,
  ),
  _PageData(
    title: 'Track Your\nEarnings',
    subtitle:
        'Monitor daily earnings, weekly bonuses, and withdraw instantly to your mobile money wallet.',
    mainIcon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF00897B),
    accentLight: Color(0xFFB2DFDB),
    badge: 'Instant Payout',
    badgeIcon: Icons.trending_up_rounded,
  ),
  _PageData(
    title: 'Safe &\nAlways Supported',
    subtitle:
        'Verified customers, full coverage and a dedicated team available 24/7 for every ride you make.',
    mainIcon: Icons.verified_user_rounded,
    color: Color(0xFF5C6BC0),
    accentLight: Color(0xFFC5CAE9),
    badge: '24/7 Support',
    badgeIcon: Icons.headset_mic_rounded,
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class OnboardingIntroScreen extends StatefulWidget {
  const OnboardingIntroScreen({super.key});

  @override
  State<OnboardingIntroScreen> createState() => _OnboardingIntroScreenState();
}

class _OnboardingIntroScreenState extends State<OnboardingIntroScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();

  // Entry animation — restarted on every page change
  late AnimationController _entryCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Continuous floating animation for the main icon
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scaleAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _entryCtrl
      ..reset()
      ..forward();
    HapticFeedback.selectionClick();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go(AppRoutes.signup);
    }
  }

  void _skip() => context.go(AppRoutes.signup);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.05,
                vertical: size.height * 0.008,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentPage + 1} / ${_pages.length}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: _scaledFont(size, 13),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: page.color.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: page.color,
                        fontSize: _scaledFont(size, 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── PageView ───────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (_, i) => _OnboardingPage(
                  data: _pages[i],
                  scaleAnim: _scaleAnim,
                  fadeAnim: _fadeAnim,
                  slideAnim: _slideAnim,
                  floatAnim: _floatAnim,
                ),
              ),
            ),

            // ── Bottom: dots + button ──────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                size.width * 0.06,
                size.height * 0.01,
                size.width * 0.06,
                size.height * 0.04,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Dot indicators
                  Row(
                    children: List.generate(_pages.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(right: 7),
                        width: active ? 28.0 : 9.0,
                        height: 9.0,
                        decoration: BoxDecoration(
                          color: active
                              ? page.color
                              : page.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    height: _buttonHeight(size),
                    width: isLast ? size.width * 0.52 : _buttonHeight(size),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          page.color,
                          page.color.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(_buttonHeight(size) / 2),
                      boxShadow: [
                        BoxShadow(
                          color: page.color.withValues(alpha: 0.38),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _next,
                        borderRadius:
                            BorderRadius.circular(_buttonHeight(size) / 2),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: isLast
                                ? Text(
                                    'Get Started',
                                    key: const ValueKey('start'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: _scaledFont(size, 16),
                                      letterSpacing: 0.3,
                                    ),
                                  )
                                : const Icon(
                                    Icons.arrow_forward_rounded,
                                    key: ValueKey('arrow'),
                                    color: Colors.white,
                                    size: 24,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _scaledFont(Size s, double base) =>
      base * (s.width / 390).clamp(0.82, 1.25);

  double _buttonHeight(Size s) => (s.height * 0.072).clamp(50.0, 62.0);
}

// ── Page widget ───────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _PageData data;
  final Animation<double> scaleAnim;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final Animation<double> floatAnim;

  const _OnboardingPage({
    required this.data,
    required this.scaleAnim,
    required this.fadeAnim,
    required this.slideAnim,
    required this.floatAnim,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = size.width * 0.07;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        children: [
          // ── Illustration ─────────────────────────────────────────────────
          Expanded(
            flex: 58,
            child: ScaleTransition(
              scale: scaleAnim,
              child: _Illustration(data: data, floatAnim: floatAnim),
            ),
          ),

          SizedBox(height: size.height * 0.025),

          // ── Text content ─────────────────────────────────────────────────
          Expanded(
            flex: 42,
            child: SlideTransition(
              position: slideAnim,
              child: FadeTransition(
                opacity: fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: TextStyle(
                        fontSize:
                            (size.width * 0.068).clamp(22.0, 34.0),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A202C),
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: size.height * 0.014),
                    Text(
                      data.subtitle,
                      style: TextStyle(
                        fontSize:
                            (size.width * 0.038).clamp(13.0, 18.0),
                        color: const Color(0xFF718096),
                        height: 1.65,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Illustration ──────────────────────────────────────────────────────────────

class _Illustration extends StatelessWidget {
  final _PageData data;
  final Animation<double> floatAnim;

  const _Illustration({required this.data, required this.floatAnim});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final s = math.min(constraints.maxWidth, constraints.maxHeight);

      return Center(
        child: SizedBox(
          width: s,
          height: s,
          child: Stack(
            children: [
              // Background radial blob
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        data.accentLight,
                        data.accentLight.withValues(alpha: 0.35),
                        Colors.white,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

              // Decorative floating circles
              ..._floatingCircles(s),

              // Main icon — animated float
              Center(
                child: AnimatedBuilder(
                  animation: floatAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, floatAnim.value),
                    child: child,
                  ),
                  child: Container(
                    width: s * 0.5,
                    height: s * 0.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          data.color,
                          data.color.withValues(alpha: 0.72),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: data.color.withValues(alpha: 0.38),
                          blurRadius: 36,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Icon(
                      data.mainIcon,
                      size: s * 0.22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Badge chip
              Positioned(
                bottom: s * 0.055,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.09),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(data.badgeIcon, color: data.color, size: 16),
                        const SizedBox(width: 7),
                        Text(
                          data.badge,
                          style: TextStyle(
                            color: data.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // Decorative circles positioned relative to the container centre
  List<Widget> _floatingCircles(double s) {
    const specs = [
      (dx: -0.38, dy: -0.16, r: 0.065),
      (dx: 0.35, dy: -0.22, r: 0.05),
      (dx: -0.30, dy: 0.28, r: 0.055),
      (dx: 0.36, dy: 0.22, r: 0.075),
      (dx: 0.06, dy: -0.41, r: 0.042),
      (dx: -0.12, dy: 0.40, r: 0.038),
    ];

    return specs.map((c) {
      final size = s * c.r * 2;
      final left = s / 2 + c.dx * s - size / 2;
      final top = s / 2 + c.dy * s - size / 2;
      return Positioned(
        left: left,
        top: top,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: data.color.withValues(alpha: 0.16),
          ),
        ),
      );
    }).toList();
  }
}
