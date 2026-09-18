import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';
import 'package:delivery_boy/features/rider/kyc/providers/kyc_providers.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_form_mixin.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_layout.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_date_picker_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';

/// Riders must be adults; the date picker won't offer anything younger.
const _minimumAge = 18;

class PersonalSection extends ConsumerStatefulWidget {
  const PersonalSection({super.key, required this.profile});

  final RiderMeProfileModel profile;

  @override
  ConsumerState<PersonalSection> createState() => _PersonalSectionState();
}

class _PersonalSectionState extends ConsumerState<PersonalSection>
    with KycSectionFormMixin {
  @override
  KycSection get section => KycSection.personal;

  late final _addressCtrl =
      TextEditingController(text: widget.profile.residentialAddress);
  late DateTime? _dateOfBirth = kycParseDate(widget.profile.dateOfBirth);

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(kycActionsProvider.select((s) => s.isSaving));
    final now = DateTime.now();
    final latestBirthDate = DateTime(now.year - _minimumAge, now.month, now.day);

    return Form(
      key: formKey,
      child: KycSectionLayout(
        section: section,
        primaryLabel: 'Save & continue',
        isBusy: isSaving,
        onPrimary: _save,
        children: [
          AppDatePickerField(
            label: 'Date of birth',
            initialDate: _dateOfBirth,
            firstDate: DateTime(1940),
            lastDate: latestBirthDate,
            prefixIcon: HugeIcons.strokeRoundedCalendar03,
            onDateSelected: (date) {
              clearServerError('date_of_birth');
              setState(() => _dateOfBirth = date);
            },
            validator: (_) =>
                serverError('date_of_birth') ??
                (_dateOfBirth == null ? 'Select your date of birth' : null),
          ),
          AppTextField(
            label: 'Home address',
            hint: 'House number, street and area',
            prefixIcon: HugeIcons.strokeRoundedLocation01,
            controller: _addressCtrl,
            maxLines: 2,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: (_) => clearServerError('residential_address'),
            validator: (v) =>
                serverError('residential_address') ??
                ((v ?? '').trim().length < 5 ? 'Enter your home address' : null),
          ),
        ],
      ),
    );
  }

  void _save() => submit(
        () => ref.read(kycActionsProvider.notifier).saveProfile({
          'date_of_birth': kycApiDate(_dateOfBirth!),
          'residential_address': _addressCtrl.text.trim(),
        }),
      );
}
