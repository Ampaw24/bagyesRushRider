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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.screenWidth * 0.03,
        vertical: widget.screenWidth * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          Text(
            '+233',
            style: TextStyle(
              fontSize: widget.screenWidth * 0.038,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(width: widget.screenWidth * 0.02),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.phone,
              style: TextStyle(fontSize: widget.screenWidth * 0.04),
              decoration: InputDecoration(
                hintText: '00 000 0000',
                hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: widget.screenWidth * 0.036),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: widget.onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}
