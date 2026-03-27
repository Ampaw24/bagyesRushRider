import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';

class _CountryCode {
  final String flag;
  final String code;
  final String country;

  const _CountryCode(this.flag, this.code, this.country);
}

const _countryCodes = [
  _CountryCode('🇬🇭', '+233', 'Ghana'),
  _CountryCode('🇳🇬', '+234', 'Nigeria'),
  _CountryCode('🇰🇪', '+254', 'Kenya'),
  _CountryCode('🇿🇦', '+27', 'South Africa'),
  _CountryCode('🇹🇿', '+255', 'Tanzania'),
  _CountryCode('🇺🇸', '+1', 'United States'),
  _CountryCode('🇬🇧', '+44', 'United Kingdom'),
];

/// Phone number input with country code selector.
/// Calls [onChanged] with the full number (countryCode + digits).
/// No floating label — place a label Text widget above this widget in your layout.
class AppPhoneField extends StatefulWidget {
  final void Function(String fullNumber)? onChanged;
  final String? Function(String?)? validator;
  final TextEditingController? digitController;
  final String initialCountryCode;

  const AppPhoneField({
    super.key,
    this.onChanged,
    this.validator,
    this.digitController,
    this.initialCountryCode = '+233',
  });

  @override
  State<AppPhoneField> createState() => _AppPhoneFieldState();
}

class _AppPhoneFieldState extends State<AppPhoneField> {
  late _CountryCode _selected;
  late String _selectedCode;
  late TextEditingController _ctrl;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.initialCountryCode;
    _selected = _countryCodes.firstWhere(
      (c) => c.code == _selectedCode,
      orElse: () => _countryCodes.first,
    );
    _ctrl = widget.digitController ?? TextEditingController();
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() => _isFocused = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (widget.digitController == null) _ctrl.dispose();
    super.dispose();
  }

  // Max local digits allowed per country code
  int get _maxDigits => _selectedCode == '+233' ? 9 : 11;

  // Contextual hint text
  String get _hintText => _selectedCode == '+233' ? '244 000 0000' : '000 000 0000';

  void _notify() {
    widget.onChanged?.call('$_selectedCode${_ctrl.text.trim()}');
  }

  void _showCountryPicker(BuildContext ctx, FormFieldState<String> state) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ..._countryCodes.map((c) => ListTile(
                leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                title: Text(
                  c.country,
                  style: const TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: Text(
                  c.code,
                  style: const TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selected = c;
                    _selectedCode = c.code;
                    // Strip leading zero when switching to Ghana
                    if (c.code == '+233' && _ctrl.text.startsWith('0')) {
                      final stripped = _ctrl.text.replaceFirst(RegExp(r'^0+'), '');
                      _ctrl.value = TextEditingValue(
                        text: stripped,
                        selection: TextSelection.collapsed(offset: stripped.length),
                      );
                    }
                  });
                  _notify();
                  state.didChange('${c.code}${_ctrl.text.trim()}');
                  Navigator.pop(_);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: '',
      validator: widget.validator ??
          (v) {
            final digits = _ctrl.text.trim();
            if (_selectedCode == '+233') {
              if (digits.isEmpty) return 'Enter your phone number';
              if (digits.startsWith('0')) return 'Remove the leading zero — use +233 format';
              if (digits.length != 9) return 'Ghana number must be exactly 9 digits';
            } else {
              if (digits.length < 9) return 'Enter a valid phone number';
            }
            return null;
          },
      builder: (FormFieldState<String> state) {
        final borderColor = state.hasError
            ? AppColors.error
            : _isFocused
                ? AppColors.primary
                : AppColors.border;
        final borderWidth = (state.hasError || _isFocused) ? 2.0 : 1.5;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: borderWidth),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Country code picker ────────────────────────────
                  GestureDetector(
                    onTap: () => _showCountryPicker(context, state),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      color: Colors.transparent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _selected.flag,
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selected.code,
                            style: const TextStyle(
                              fontFamily: 'Mukta',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            HugeIcons.strokeRoundedArrowDown01,
                            size: 22,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Vertical divider ───────────────────────────────
                  Container(
                    width: 1,
                    height: 28,
                    color: AppColors.border,
                  ),

                  // ── Phone digit input ──────────────────────────────
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        _PhoneDigitFormatter(
                          countryCode: _selectedCode,
                          maxDigits: _maxDigits,
                        ),
                      ],
                      onChanged: (v) {
                        _notify();
                        state.didChange('$_selectedCode${v.trim()}');
                      },
                      style: const TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: _hintText,
                        hintStyle: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),

                ],
              ),
            ),

            // ── Error text ─────────────────────────────────────────
            if (state.hasError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Formatter that:
/// - Allows digits only
/// - For Ghana (+233): strips leading zeros and caps at [maxDigits]
/// - For all others: caps at [maxDigits] only
class _PhoneDigitFormatter extends TextInputFormatter {
  final String countryCode;
  final int maxDigits;

  const _PhoneDigitFormatter({
    required this.countryCode,
    required this.maxDigits,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Keep digits only
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Ghana: block leading zero entirely
    if (countryCode == '+233') {
      text = text.replaceFirst(RegExp(r'^0+'), '');
    }

    // Enforce max length
    if (text.length > maxDigits) text = text.substring(0, maxDigits);

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
