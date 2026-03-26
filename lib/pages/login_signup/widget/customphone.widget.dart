import 'package:delivery_boy/pages/login_signup/widget/modern_phoneinput.dart';
import 'package:flutter/material.dart';

Widget buildPhoneInputSection({
  bool loading = false,
  required TextEditingController phoneController,
  required FocusNode phoneFocusNode,
  required void Function(String) onChanged,
  required BuildContext context,
}) {
  return ModernPhoneInput(
    controller: phoneController,
    focusNode: phoneFocusNode,
    enabled: !loading,
    onChanged: onChanged,
  );
}
