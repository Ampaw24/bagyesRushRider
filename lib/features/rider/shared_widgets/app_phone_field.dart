import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late String _selectedCode;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.initialCountryCode;
    _ctrl = widget.digitController ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.digitController == null) _ctrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged?.call('$_selectedCode${_ctrl.text.trim()}');
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => _notify(),
      validator: widget.validator ??
          (v) {
            if (v == null || v.trim().length < 9) {
              return 'Enter a valid phone number';
            }
            return null;
          },
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: 'Phone Number',
        hintText: '024 000 0000',
        prefixIcon: _CountryCodePicker(
          selected: _selectedCode,
          onChanged: (code) {
            setState(() => _selectedCode = code);
            _notify();
          },
        ),
        hintStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          color: Colors.grey.shade400,
        ),
        labelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          color: Colors.grey.shade500,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.only(
            left: 0, right: 16, top: 18, bottom: 18),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}

class _CountryCodePicker extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const _CountryCodePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 24, color: Colors.grey.shade500),
          items: _countryCodes
              .map((c) => DropdownMenuItem(
                    value: c.code,
                    child: Text(
                      '${c.flag} ${c.code}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          selectedItemBuilder: (_) => _countryCodes
              .map((c) => Center(
                    child: Text(
                      '${c.flag} ${c.code}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
