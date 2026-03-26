// Modern Phone Input Component
import 'package:flutter/material.dart';

class ModernPhoneInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final double screenWidth;
  final Function(String)? onSubmitted;

  const ModernPhoneInput({
    required this.controller,
    required this.focusNode,
    required this.screenWidth,
    this.enabled = true,
    this.onSubmitted,
  });

  @override
  State<ModernPhoneInput> createState() => ModernPhoneInputState();
}

class ModernPhoneInputState extends State<ModernPhoneInput> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
