import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:delivery_boy/constant/app_theme.dart';

/// Caps a digit box on wide layouts (tablets, landscape) so the row keeps
/// phone proportions instead of stretching edge to edge.
const double _kMaxBoxWidth = 64;

/// Box outline stroke — thicker once a box is in use.
const double _kBorderIdle = 1.2;
const double _kBorderActive = 1.8;

/// Row of single-digit boxes for a verification code, matching the
/// customer/vendor app's OTP design.
///
/// Handles focus movement, backspace and pasting (or SMS-autofilling) a
/// whole code. Box colours follow [hasError] and [isSuccess]; the owning
/// screen reaches [OtpCodeInputState.shake] and [OtpCodeInputState.clear]
/// through a `GlobalKey<OtpCodeInputState>`.
class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({
    super.key,
    this.length = 6,
    this.enabled = true,
    this.hasError = false,
    this.isSuccess = false,
    required this.onChanged,
    required this.onCompleted,
  });

  /// How long the success bounce runs, so a caller can let it finish
  /// before navigating away.
  static const successDuration = Duration(milliseconds: 600);

  final int length;
  final bool enabled;
  final bool hasError;
  final bool isSuccess;

  /// Every edit, with the (possibly partial) code.
  final ValueChanged<String> onChanged;

  /// Every box is filled — by typing the last digit or by pasting.
  final ValueChanged<String> onCompleted;

  @override
  State<OtpCodeInput> createState() => OtpCodeInputState();
}

class OtpCodeInputState extends State<OtpCodeInput>
    with TickerProviderStateMixin {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late final AnimationController _shakeCtrl;
  late final AnimationController _successCtrl;
  late final Animation<double> _successScale;

  String get code => _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(
      widget.length,
      (_) => FocusNode()..addListener(_onFocusChange),
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _successCtrl = AnimationController(
      vsync: this,
      duration: OtpCodeInput.successDuration,
    );
    _successScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.14), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _successCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(OtpCodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSuccess && !oldWidget.isSuccess && !_reduceMotion) {
      _successCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _shakeCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Empties every box and returns focus to the first.
  ///
  /// Focus waits a frame: callers typically clear straight after a failed
  /// check, while the boxes are still disabled and can't take focus.
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.enabled) _focusNodes.first.requestFocus();
    });
  }

  /// Horizontal shake that signals a rejected code.
  void shake() {
    if (!_reduceMotion) _shakeCtrl.forward(from: 0);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _onBoxChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
    setState(() {});
    _emit();
  }

  void _onBackspaceOnEmpty(int index) {
    if (index == 0) return;
    _controllers[index - 1].clear();
    _focusNodes[index - 1].requestFocus();
    setState(() {});
    _emit();
  }

  void _onPaste(String digits) {
    if (!mounted) return;
    final pasted = digits.substring(0, math.min(digits.length, widget.length));
    for (var i = 0; i < widget.length; i++) {
      _controllers[i].text = i < pasted.length ? pasted[i] : '';
    }
    if (pasted.length == widget.length) {
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      _focusNodes[pasted.length].requestFocus();
    }
    setState(() {});
    _emit();
  }

  void _emit() {
    final current = code;
    widget.onChanged(current);
    if (current.length == widget.length) widget.onCompleted(current);
  }

  ({Color border, Color fill}) _lookFor({required bool inUse}) {
    if (widget.isSuccess) {
      return (
        border: AppColors.success,
        fill: AppColors.success.withValues(alpha: 0.12),
      );
    }
    if (widget.hasError) {
      return (
        border: AppColors.error,
        fill: AppColors.error.withValues(alpha: 0.06),
      );
    }
    if (inUse) return (border: AppColors.primary, fill: Colors.white);
    return (border: AppColors.border, fill: AppColors.surfaceVariant);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth * 0.026;
        final boxWidth = math.min(
          (constraints.maxWidth - gap * (widget.length - 1)) / widget.length,
          _kMaxBoxWidth,
        );

        return AnimatedBuilder(
          animation: _shakeCtrl,
          builder: (context, child) {
            final t = _shakeCtrl.value;
            final dx = math.sin(t * math.pi * 6) * boxWidth * 0.2 * (1 - t);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Semantics(
            label: 'Verification code',
            container: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  ScaleTransition(
                    scale: widget.isSuccess
                        ? _successScale
                        : kAlwaysCompleteAnimation,
                    child: _buildBox(i, boxWidth),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBox(int i, double width) {
    final inUse = _focusNodes[i].hasFocus || _controllers[i].text.isNotEmpty;
    final look = _lookFor(inUse: inUse);
    final highlighted = inUse || widget.hasError || widget.isSuccess;

    return _OtpBox(
      width: width,
      border: look.border,
      fill: look.fill,
      borderWidth: highlighted ? _kBorderActive : _kBorderIdle,
      controller: _controllers[i],
      focusNode: _focusNodes[i],
      enabled: widget.enabled,
      autofocus: i == 0,
      isLast: i == widget.length - 1,
      onChanged: (v) => _onBoxChanged(i, v),
      onBackspaceOnEmpty: () => _onBackspaceOnEmpty(i),
      onPaste: _onPaste,
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.width,
    required this.border,
    required this.fill,
    required this.borderWidth,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.autofocus,
    required this.isLast,
    required this.onChanged,
    required this.onBackspaceOnEmpty,
    required this.onPaste,
  });

  final double width;
  final Color border;
  final Color fill;
  final double borderWidth;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool autofocus;
  final bool isLast;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspaceOnEmpty;
  final ValueChanged<String> onPaste;

  @override
  Widget build(BuildContext context) {
    final digitSize = width * 0.46;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width,
      height: width * 1.05,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(width * 0.23),
        border: Border.all(color: border, width: borderWidth),
      ),
      // Backspace on an already-empty box never reaches onChanged, so it is
      // caught here to step back into the previous box.
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspaceOnEmpty();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          autofocus: autofocus,
          keyboardType: TextInputType.number,
          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [_OtpDigitFormatter(onPaste: onPaste)],
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: digitSize,
            fontWeight: FontWeight.w700,
            height: 1.0,
            color: AppColors.textPrimary,
          ),
          strutStyle: StrutStyle(
            fontSize: digitSize,
            height: 1.0,
            forceStrutHeight: true,
          ),
          decoration: const InputDecoration(
            isDense: true,
            // The theme sets filled/bordered inputs; the box draws both.
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            counterText: '',
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Keeps a box to one digit, and turns a multi-digit paste (or SMS
/// autofill) into a whole-code fill.
///
/// Only what the edit *added* is considered, so typing over a filled box
/// replaces its digit rather than being mistaken for a two-digit paste.
///
/// A paste is handed off in a microtask: the box's own controller is
/// overwritten with this formatter's return value, so distributing the
/// digits synchronously would have the first one wiped straight away.
class _OtpDigitFormatter extends TextInputFormatter {
  _OtpDigitFormatter({required this.onPaste});

  final ValueChanged<String> onPaste;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return TextEditingValue.empty;

    final added =
        _added(oldValue.text, newValue.text).replaceAll(RegExp(r'[^0-9]'), '');

    if (added.length > 1) {
      scheduleMicrotask(() => onPaste(added));
      return oldValue;
    }
    if (added.isEmpty) return oldValue;

    return TextEditingValue(
      text: added,
      selection: const TextSelection.collapsed(offset: 1),
    );
  }

  /// The text [newText] added around [oldText] (a box holds one digit).
  static String _added(String oldText, String newText) {
    if (oldText.isEmpty) return newText;
    if (newText.startsWith(oldText)) return newText.substring(oldText.length);
    if (newText.endsWith(oldText)) {
      return newText.substring(0, newText.length - oldText.length);
    }
    return newText;
  }
}
