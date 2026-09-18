import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';
import 'package:delivery_boy/features/rider/kyc/providers/kyc_providers.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_document_field.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_metrics.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_layout.dart';

/// Requirements the server reports that this version of the app doesn't
/// recognise. Unknown documents can still be uploaded (the endpoint is
/// generic); unknown fields are listed so the rider knows to ask support.
class OtherRequirementsSection extends ConsumerWidget {
  const OtherRequirementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = KycMetrics.of(context);
    final progress = ref.watch(kycProgressProvider)?.progressOf(KycSection.other);
    final fields = progress?.missingFields ?? const [];
    final documents = progress?.pendingDocuments ?? const [];

    return KycSectionLayout(
      section: KycSection.other,
      primaryLabel: 'Back to checklist',
      onPrimary: () => context.go(AppRoutes.kyc),
      children: [
        for (final slug in documents) KycDocumentField(slug: slug),
        if (fields.isNotEmpty) ...[
          const KycSubheading(
            'Details our team still needs',
            caption: 'Contact support and they will help you add these.',
          ),
          for (final field in fields)
            Row(
              children: [
                Icon(
                  HugeIcons.strokeRoundedAlert02,
                  size: m.iconBadge * 0.4,
                  color: AppColors.warning,
                ),
                SizedBox(width: m.gutter * 0.5),
                Expanded(
                  child: Text(
                    kycLabel(field),
                    style: TextStyle(
                      fontSize: m.bodySize,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
        ],
        if (fields.isEmpty && documents.isEmpty)
          Text(
            'Nothing else is needed here.',
            style: TextStyle(
              fontSize: m.bodySize,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}
