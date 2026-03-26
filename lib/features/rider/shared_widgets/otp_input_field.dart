import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:delivery_boy/constant/app_theme.dart';

/// A reusable N-digit OTP input widget with auto-advance and backspace support.
/// Calls [onCompleted] when all [digitCount] boxes are filled.
class OtpInputField extends StatefulWidget {
  final int digitCount;
  final void Function(String otp)? onCompleted;
  final bool enabled;

  const OtpInputField({
    super.key,
    this.digitCount = 6,
    this.onCompleted,
    this.enabled = true,
  });

  @override
  State<OtpInputField> createState() => OtpInputFieldState();
}

class OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(widget.digitCount, (_) => TextEditingController());
    _focusNodes = List.generate(widget.digitCount, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp =>
      _controllers.map((c) => c.text).join();

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes.first.requestFocus();
    }
    setState(() {});
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1) {
      if (index < widget.digitCount - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // All boxes filled — trigger callback
        final otp = _currentOtp;
        if (otp.length == widget.digitCount) {
          widget.onCompleted?.call(otp);
        }
      }
    }
    setState(() {});
    // Check completion on any change
    final otp = _currentOtp;
    if (otp.length == widget.digitCount) {
      widget.onCompleted?.call(otp);
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        widget.digitCount,
        (i) => _PinBox(
          controller: _controllers[i],
          focusNode: _focusNodes[i],
          enabled: widget.enabled,
          onChanged: (v) => _onDigitChanged(i, v),
          onBackspace: i > 0 ? () => _onBackspace(i) : null,
        ),
      ),
    );
  }
}

class _PinBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final void Function(String) onChanged;
  final VoidCallback? onBackspace;

  const _PinBox({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
    this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 54,
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
          enabled: enabled,
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
              borderSide:
                  BorderSide(color: Colors.grey.shade200, width: 1.5),
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
