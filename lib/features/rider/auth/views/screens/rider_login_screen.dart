import 'package:delivery_boy/pages/login_signup/widget/customphone.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/asset_images.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';

class RiderLoginScreen extends ConsumerStatefulWidget {
  const RiderLoginScreen({super.key});

  @override
  ConsumerState<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends ConsumerState<RiderLoginScreen>
    with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;
  String _phone = '';
  String _password = '';
  String _selectedCountryCode = '+233';
  DateTime? _lastBackPress;

  late TextEditingController _phoneController;
  late FocusNode _phoneFocusNode;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _phoneFocusNode = FocusNode();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  bool get _isFilled => _phone.isNotEmpty && _password.isNotEmpty;

  Future<void> _login() async {
    final success = await ref.read(riderAuthProvider.notifier).login(
          phone: '$_selectedCountryCode$_phone',
          password: _password,
        );
    if (success && mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  Widget _buildInputField({
    required Widget prefixWidget,
    required String hint,
    required void Function(String) onChanged,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixWidget,
  }) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          prefixWidget,
          Expanded(
            child: TextField(
              obscureText: obscure,
              enableSuggestions: !obscure,
              autocorrect: !obscure,
              keyboardType: keyboardType,
              style: TextStyle(
                  fontSize: width * 0.04, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                    color: Colors.grey.shade400, fontSize: width * 0.036),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: width * 0.032, vertical: height * 0.022),
              ),
              onChanged: (v) => onChanged(v.trim()),
            ),
          ),
          if (suffixWidget != null) suffixWidget,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(riderAuthProvider);
    final isLoading = authState.status == AuthStatus.loading;

    // Show error snackbar
    ref.listen<RiderAuthState>(riderAuthProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red.shade700,
          ),
        );
        ref.read(riderAuthProvider.notifier).clearError();
      }
    });

    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final horizontalPadding = width * 0.064;
    final spaceXL = height * 0.054;
    final spaceL = height * 0.043;
    final spaceM = height * 0.027;
    final spaceS = height * 0.016;
    final controlHeight = height * 0.075;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          Fluttertoast.showToast(
            msg: 'Press Back Once Again to Exit.',
            backgroundColor: Colors.black,
            textColor: whiteColor,
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: scaffoldBgColor,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: spaceXL),

                    // Logo
                    Center(
                      child: Container(
                        width: width * 0.24,
                        height: width * 0.24,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            AssetImages.deliveryBoy,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: spaceL),

                    Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: width * 0.074,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: spaceS),
                    Text(
                      'Sign in to continue delivering',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    SizedBox(height: spaceM),
                    buildPhoneInputSection(
                      loading: isLoading,
                      sw: width,
                      phoneController: _phoneController,
                      phoneFocusNode: _phoneFocusNode,
                      proceed: (_) =>
                          setState(() => _phone = _phoneController.text.trim()),
                      context: context,
                    ),

                    SizedBox(height: spaceS),

                    Text(
                      'Password',
                      style: TextStyle(
                        fontSize: width * 0.034,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: spaceS),
                    _buildInputField(
                      prefixWidget: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: width * 0.036),
                        child: Icon(Icons.lock_outline_rounded,
                            size: width * 0.053, color: Colors.grey.shade400),
                      ),
                      hint: 'Enter your password',
                      obscure: _obscurePassword,
                      onChanged: (v) => setState(() => _password = v),
                      suffixWidget: GestureDetector(
                        onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        child: Padding(
                          padding: EdgeInsets.only(right: width * 0.036),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.forgotPassword),
                        style: TextButton.styleFrom(
                            padding:
                                EdgeInsets.symmetric(vertical: height * 0.012)),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: spaceS),

                    SizedBox(
                      width: double.infinity,
                      height: controlHeight,
                      child: ElevatedButton(
                        onPressed: (isLoading || !_isFilled) ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor:
                              primaryColor.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isLoading
                            ? const SpinKitRing(
                                color: Colors.white,
                                lineWidth: 2,
                                size: 24,
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: spaceL),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.signup),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
