import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';

class RiderOtpScreen extends ConsumerStatefulWidget {
  /// Passed via GoRouter extra: {'phone': String, 'password': String}
  final Map<String, dynamic> credentials;

  const RiderOtpScreen({super.key, required this.credentials});

  @override
  ConsumerState<RiderOtpScreen> createState() => _RiderOtpScreenState();
}

class _RiderOtpScreenState extends ConsumerState<RiderOtpScreen> {
  String _otp = '';

  String get _phone => widget.credentials['phone'] as String? ?? '';
  String get _password => widget.credentials['password'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp());
  }

  Future<void> _sendOtp() async {
    if (_phone.isEmpty) {
      context.go(AppRoutes.signup);
      return;
    }
    await ref
        .read(riderAuthProvider.notifier)
        .sendOtp(phone: _phone);
  }

  Future<void> _submit() async {
    if (_otp.length < 5) return;

    final success = await ref.read(riderAuthProvider.notifier).signup(
          phone: _phone,
          password: _password,
          otp: _otp,
        );

    if (!mounted) return;
    if (success) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Success!'),
          content: const Text('User account created successfully'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go(AppRoutes.dashboard);
              },
              child: Text('Okay', style: TextStyle(color: primaryColor)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(riderAuthProvider);
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen<RiderAuthState>(riderAuthProvider, (_, next) {
      if (next.errorMessage != null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Oops!'),
            content: Text(next.errorMessage!),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(riderAuthProvider.notifier).clearError();
                },
                child: Text('Okay', style: TextStyle(color: primaryColor)),
              ),
            ],
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go(AppRoutes.signup),
        ),
      ),
      body: ListView(
        children: [
          Container(
            padding: EdgeInsets.all(fixPadding * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verification', style: bigHeadingStyle),
                heightSpace,
                Text(
                  'Enter the OTP code from the phone we just sent you.',
                  style: lightGreyStyle,
                ),
                heightSpace,
                heightSpace,
                heightSpace,
                heightSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 1.5,
                            spreadRadius: 1.5,
                            color: Colors.grey.shade200,
                          ),
                        ],
                      ),
                      child: TextField(
                        style: headingStyle,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(18),
                          border: InputBorder.none,
                        ),
                        onChanged: (v) => setState(() => _otp = v.trim()),
                      ),
                    ),
                  ],
                ),
                heightSpace,
                heightSpace,
                heightSpace,
                heightSpace,
                heightSpace,
                heightSpace,
                Row(
                  children: [
                    Text("Didn't receive OTP Code!", style: lightGreyStyle),
                    widthSpace,
                    InkWell(
                      onTap: isLoading ? null : _sendOtp,
                      child: Text('Resend', style: listItemTitleStyle),
                    ),
                  ],
                ),
                heightSpace,
                heightSpace,
                heightSpace,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: fixPadding),
                  child: InkWell(
                    onTap: isLoading ? null : _submit,
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: primaryColor,
                      ),
                      child: isLoading
                          ? const SpinKitRing(
                              color: Colors.white,
                              lineWidth: 2,
                              size: 25,
                            )
                          : Text('Submit', style: wbuttonWhiteTextStyle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
