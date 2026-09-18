import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';
import 'package:delivery_boy/features/rider/kyc/providers/kyc_providers.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_document_field.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_form_mixin.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_layout.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_date_picker_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_select_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';

/// Ghana DVLA licence classes. The API doesn't publish its accepted values;
/// if it rejects one, its message is shown on this field.
const licenceClasses = {
  'A': 'A — Motorcycles and tricycles',
  'B': 'B — Cars and light vehicles',
  'C': 'C — Light trucks and minibuses',
  'D': 'D — Buses',
  'E': 'E — Heavy goods vehicles',
  'F': 'F — Articulated vehicles',
};

class LicenceSection extends ConsumerStatefulWidget {
  const LicenceSection({super.key, required this.profile});

  final RiderMeProfileModel profile;

  @override
  ConsumerState<LicenceSection> createState() => _LicenceSectionState();
}

class _LicenceSectionState extends ConsumerState<LicenceSection>
    with KycSectionFormMixin {
  @override
  KycSection get section => KycSection.licence;

  late final _numberCtrl =
      TextEditingController(text: widget.profile.licenceNumber);
  late final _permitCtrl =
      TextEditingController(text: widget.profile.riderPermitNumber);
  late String? _class = widget.profile.licenceClass;
  late DateTime? _expiresAt = kycParseDate(widget.profile.licenceExpiresAt);
  late DateTime? _permitExpiresAt =
      kycParseDate(widget.profile.riderPermitExpiresAt);

  @override
  void dispose() {
    _numberCtrl.dispose();
    _permitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(kycActionsProvider.select((s) => s.isSaving));
    final today = DateUtils.dateOnly(DateTime.now());
    final latestExpiry = DateTime(today.year + 20);
    final isExpired = widget.profile.expiredCredentials.contains('licence');

    return Form(
      key: formKey,
      child: KycSectionLayout(
        section: section,
        primaryLabel: 'Save & continue',
        isBusy: isSaving,
        onPrimary: _save,
        children: [
          AppTextField(
            label: 'Licence number',
            prefixIcon: HugeIcons.strokeRoundedCreditCard,
            controller: _numberCtrl,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => clearServerError('licence_number'),
            validator: (v) =>
                serverError('licence_number') ??
                ((v ?? '').trim().length < 4 ? 'Enter your licence number' : null),
          ),
          AppSelectField<String>(
            label: 'Licence class',
            hint: 'Select the class on your licence',
            value: licenceClasses.containsKey(_class) ? _class : null,
            options: licenceClasses.keys.toList(),
            labelBuilder: (c) => licenceClasses[c]!,
            prefixIcon: HugeIcons.strokeRoundedMotorbike01,
            onChanged: (c) {
              clearServerError('licence_class');
              setState(() => _class = c);
            },
            validator: (c) =>
                serverError('licence_class') ??
                (c == null ? 'Select your licence class' : null),
          ),
          AppDatePickerField(
            label: isExpired ? 'Expiry date — renewal needed' : 'Expiry date',
            initialDate: _expiresAt,
            firstDate: today,
            lastDate: latestExpiry,
            onDateSelected: (d) {
              clearServerError('licence_expires_at');
              setState(() => _expiresAt = d);
            },
            validator: (_) =>
                serverError('licence_expires_at') ?? _futureDate(_expiresAt),
          ),
          const KycSubheading('Photos of your licence'),
          const KycDocumentField(slug: 'drivers_licence_front'),
          const KycDocumentField(slug: 'drivers_licence_back'),
          const KycSubheading(
            'Rider permit',
            caption: 'Optional — add it if you have one.',
          ),
          AppTextField(
            label: 'Permit number',
            prefixIcon: HugeIcons.strokeRoundedDocumentValidation,
            controller: _permitCtrl,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onChanged: (_) => clearServerError('rider_permit_number'),
            validator: (_) => serverError('rider_permit_number'),
          ),
          AppDatePickerField(
            label: 'Permit expiry date',
            initialDate: _permitExpiresAt,
            firstDate: today,
            lastDate: latestExpiry,
            onDateSelected: (d) {
              clearServerError('rider_permit_expires_at');
              setState(() => _permitExpiresAt = d);
            },
            validator: (_) =>
                serverError('rider_permit_expires_at') ??
                (_permitCtrl.text.trim().isNotEmpty && _permitExpiresAt == null
                    ? 'Add the permit expiry date'
                    : null),
          ),
          KycDocumentField(
            slug: 'rider_permit',
            required:
                widget.profile.documents['rider_permit']?.required ?? false,
          ),
        ],
      ),
    );
  }

  String? _futureDate(DateTime? date) {
    if (date == null) return 'Select the expiry date';
    if (date.isBefore(DateUtils.dateOnly(DateTime.now()))) {
      return 'This licence has expired — renew it to continue';
    }
    return null;
  }

  void _save() {
    final permit = _permitCtrl.text.trim();
    submit(
      () => ref.read(kycActionsProvider.notifier).saveProfile({
        'licence_number': _numberCtrl.text.trim(),
        'licence_class': _class,
        'licence_expires_at': kycApiDate(_expiresAt!),
        if (permit.isNotEmpty) 'rider_permit_number': permit,
        if (_permitExpiresAt != null)
          'rider_permit_expires_at': kycApiDate(_permitExpiresAt!),
      }),
    );
  }
}
