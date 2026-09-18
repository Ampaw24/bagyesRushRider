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
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';

class InsuranceSection extends ConsumerStatefulWidget {
  const InsuranceSection({super.key, required this.profile});

  final RiderMeProfileModel profile;

  @override
  ConsumerState<InsuranceSection> createState() => _InsuranceSectionState();
}

class _InsuranceSectionState extends ConsumerState<InsuranceSection>
    with KycSectionFormMixin {
  @override
  KycSection get section => KycSection.insurance;

  late final _providerCtrl =
      TextEditingController(text: widget.profile.insuranceProvider);
  late final _policyCtrl =
      TextEditingController(text: widget.profile.insurancePolicyNumber);
  late DateTime? _expiresAt = kycParseDate(widget.profile.insuranceExpiresAt);
  late DateTime? _roadworthyExpiresAt =
      kycParseDate(widget.profile.roadworthyExpiresAt);

  @override
  void dispose() {
    _providerCtrl.dispose();
    _policyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(kycActionsProvider.select((s) => s.isSaving));
    final today = DateUtils.dateOnly(DateTime.now());
    final latestExpiry = DateTime(today.year + 5);

    return Form(
      key: formKey,
      child: KycSectionLayout(
        section: section,
        primaryLabel: 'Save & continue',
        isBusy: isSaving,
        onPrimary: _save,
        children: [
          AppTextField(
            label: 'Insurance provider',
            hint: 'e.g. Enterprise Insurance',
            prefixIcon: HugeIcons.strokeRoundedShield01,
            controller: _providerCtrl,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => clearServerError('insurance_provider'),
            validator: (v) =>
                serverError('insurance_provider') ??
                ((v ?? '').trim().isEmpty ? 'Enter your insurer' : null),
          ),
          AppTextField(
            label: 'Policy number',
            prefixIcon: HugeIcons.strokeRoundedDocumentValidation,
            controller: _policyCtrl,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onChanged: (_) => clearServerError('insurance_policy_number'),
            validator: (v) =>
                serverError('insurance_policy_number') ??
                ((v ?? '').trim().isEmpty ? 'Enter the policy number' : null),
          ),
          AppDatePickerField(
            label: 'Insurance expiry date',
            initialDate: _expiresAt,
            firstDate: today,
            lastDate: latestExpiry,
            onDateSelected: (d) {
              clearServerError('insurance_expires_at');
              setState(() => _expiresAt = d);
            },
            validator: (_) =>
                serverError('insurance_expires_at') ??
                (_expiresAt == null
                    ? 'Select the expiry date'
                    : (_expiresAt!.isBefore(today)
                        ? 'This policy has expired — renew it to continue'
                        : null)),
          ),
          AppDatePickerField(
            label: 'Roadworthy expiry date (optional)',
            initialDate: _roadworthyExpiresAt,
            firstDate: today,
            lastDate: latestExpiry,
            onDateSelected: (d) {
              clearServerError('roadworthy_expires_at');
              setState(() => _roadworthyExpiresAt = d);
            },
            validator: (_) => serverError('roadworthy_expires_at'),
          ),
          const KycSubheading('Certificates'),
          const KycDocumentField(slug: 'insurance_certificate'),
          const KycDocumentField(slug: 'roadworthy_certificate'),
        ],
      ),
    );
  }

  void _save() => submit(
        () => ref.read(kycActionsProvider.notifier).saveProfile({
          'insurance_provider': _providerCtrl.text.trim(),
          'insurance_policy_number': _policyCtrl.text.trim(),
          'insurance_expires_at': kycApiDate(_expiresAt!),
          if (_roadworthyExpiresAt != null)
            'roadworthy_expires_at': kycApiDate(_roadworthyExpiresAt!),
        }),
      );
}
