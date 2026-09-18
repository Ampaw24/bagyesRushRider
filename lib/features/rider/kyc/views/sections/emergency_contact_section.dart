import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';
import 'package:delivery_boy/features/rider/kyc/providers/kyc_providers.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_form_mixin.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_layout.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_phone_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_select_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';

/// Sent as the key. The API doesn't publish its accepted values; if it
/// rejects one, its message is shown on this field.
const emergencyRelationships = {
  'parent': 'Parent',
  'spouse': 'Spouse or partner',
  'sibling': 'Brother or sister',
  'child': 'Son or daughter',
  'relative': 'Other relative',
  'friend': 'Friend',
  'other': 'Other',
};

/// The 9 local digits of a Ghana number stored as `233…`, `+233…` or `0…`.
String ghanaLocalDigits(String? phone) {
  var digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('233')) digits = digits.substring(3);
  if (digits.startsWith('0')) digits = digits.substring(1);
  return digits;
}

class EmergencyContactSection extends ConsumerStatefulWidget {
  const EmergencyContactSection({super.key, required this.profile});

  final RiderMeProfileModel profile;

  @override
  ConsumerState<EmergencyContactSection> createState() =>
      _EmergencyContactSectionState();
}

class _EmergencyContactSectionState
    extends ConsumerState<EmergencyContactSection> with KycSectionFormMixin {
  @override
  KycSection get section => KycSection.emergencyContact;

  late final _nameCtrl =
      TextEditingController(text: widget.profile.emergencyContactName);
  late final _phoneDigitsCtrl = TextEditingController(
    text: ghanaLocalDigits(widget.profile.emergencyContactPhone),
  );
  late String? _relationship = widget.profile.emergencyContactRelationship;

  /// Country code plus digits, as [AppPhoneField] reports it.
  late String _phone = '+233${_phoneDigitsCtrl.text}';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneDigitsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(kycActionsProvider.select((s) => s.isSaving));

    return Form(
      key: formKey,
      child: KycSectionLayout(
        section: section,
        primaryLabel: 'Save & continue',
        isBusy: isSaving,
        onPrimary: _save,
        children: [
          AppTextField(
            label: 'Full name',
            prefixIcon: HugeIcons.strokeRoundedUser,
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => clearServerError('emergency_contact_name'),
            validator: (v) =>
                serverError('emergency_contact_name') ??
                ((v ?? '').trim().length < 2 ? "Enter your contact's name" : null),
          ),
          AppPhoneField(
            digitController: _phoneDigitsCtrl,
            onChanged: (full) {
              clearServerError('emergency_contact_phone');
              _phone = full;
            },
            validator: (_) =>
                serverError('emergency_contact_phone') ?? _validatePhone(),
          ),
          AppSelectField<String>(
            label: 'Relationship',
            hint: 'How do you know them?',
            value: emergencyRelationships.containsKey(_relationship)
                ? _relationship
                : null,
            options: emergencyRelationships.keys.toList(),
            labelBuilder: (r) => emergencyRelationships[r]!,
            prefixIcon: HugeIcons.strokeRoundedUserGroup,
            onChanged: (r) {
              clearServerError('emergency_contact_relationship');
              setState(() => _relationship = r);
            },
            validator: (r) =>
                serverError('emergency_contact_relationship') ??
                (r == null ? 'Select the relationship' : null),
          ),
        ],
      ),
    );
  }

  String? _validatePhone() {
    final digits = _phoneDigitsCtrl.text.trim();
    if (digits.isEmpty) return "Enter your contact's phone number";
    if (!_phone.startsWith('+233')) {
      return digits.length < 9 ? 'Enter a valid phone number' : null;
    }
    if (digits.startsWith('0')) return 'Remove the leading zero';
    if (digits.length != 9) return 'Ghana numbers have 9 digits after +233';
    if (digits == ghanaLocalDigits(widget.profile.phone)) {
      return 'Use someone else’s number, not your own';
    }
    return null;
  }

  void _save() => submit(
        () => ref.read(kycActionsProvider.notifier).saveProfile({
          'emergency_contact_name': _nameCtrl.text.trim(),
          'emergency_contact_phone': _phone.trim(),
          'emergency_contact_relationship': _relationship,
        }),
      );
}
