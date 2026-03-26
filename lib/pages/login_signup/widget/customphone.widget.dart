import 'package:delivery_boy/pages/login_signup/widget/modern_phoneinput.dart';
import 'package:flutter/material.dart';

Widget buildPhoneInputSection(
    {bool loading = false,
    required double sw,
    required TextEditingController phoneController,
    required FocusNode phoneFocusNode,
    required Function(BuildContext) proceed,
    required BuildContext context}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Phone Number',
        style: TextStyle(
          fontSize: (sw * 0.037).clamp(11, 16),
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      SizedBox(height: sw * 0.032),
      ModernPhoneInput(
        controller: phoneController,
        focusNode: phoneFocusNode,
        enabled: !loading,
        screenWidth: sw,
        onSubmitted: (_) => proceed(context),
      ),
    ],
  );
}
