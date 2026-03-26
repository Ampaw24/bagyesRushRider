import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';

class RiderOtpScreen extends ConsumerStatefulWidget {
  /// Passed via GoRouter extra: {'phone': String, 'password': String}
  final Map<String, dynamic> credentials;

  const RiderOtpScreen({super.key, required this.credentials});

  @override
  ConsumerState<RiderOtpScreen> createState() => _RiderOtpScreenState();
}

class _RiderOtpScreenState extends ConsumerState<RiderOtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  int _secondsLeft = 60;
  Timer? _countdownTimer;

  String get _phone => widget.credentials['phone'] as String? ?? '';
  String get _password => widget.credentials['password'] as String? ?? '';

  String get _otp =>
      _controllers.map((c) => c.text).join();

  bool get _isComplete => _otp.length == 5;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _countdownTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsLeft = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  Future<void> _sendOtp() async {
    if (_phone.isEmpty) {
      context.go(AppRoutes.signup);
      return;
    }
    await ref.read(riderAuthProvider.notifier).sendOtp(phone: _phone);
    _startCountdown();
  }

  Future<void> _submit() async {
    if (!_isComplete) return;
    HapticFeedback.lightImpact();

    final success = await ref.read(riderAuthProvider.notifier).signup(
          phone: _phone,
          password: _password,
          otp: _otp,
        );

    if (!mounted) return;
    if (success) {
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Welcome!',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'Your account has been created successfully.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go(AppRoutes.dashboard);
              },
              child: const Text(
                'Get Started',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 4) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(riderAuthProvider);
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen<RiderAuthState>(riderAuthProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(riderAuthProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.go(AppRoutes.signup),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                const Text(
                  'Verify Phone',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    children: [
                      const TextSpan(text: 'Enter the 5-digit code sent to '),
                      TextSpan(
                        text: _phone,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 44),

                // ── 5 pin boxes ────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (i) => _PinBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    onChanged: (v) => _onDigitChanged(i, v),
                    onBackspace: i > 0
                        ? () {
                            if (_controllers[i].text.isEmpty) {
                              _focusNodes[i - 1].requestFocus();
                              _controllers[i - 1].clear();
                              setState(() {});
                            }
                          }
                        : null,
                  )),
                ),

                const SizedBox(height: 40),

                // ── Countdown / Resend ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive a code? ",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    _secondsLeft > 0
                        ? Text(
                            'Resend in ${_secondsLeft}s',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : GestureDetector(
                            onTap: isLoading ? null : _sendOtp,
                            child: const Text(
                              'Resend',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ],
                ),

                const SizedBox(height: 40),

                AppGradientButton(
                  label: 'Verify & Continue',
                  isLoading: isLoading,
                  onPressed: (_isComplete && !isLoading) ? _submit : null,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual pin box with auto-advance and backspace support
class _PinBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;
  final VoidCallback? onBackspace;

  const _PinBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 60,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspace?.call();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: focusNode.hasFocus
                ? AppColors.primary.withValues(alpha: 0.05)
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
