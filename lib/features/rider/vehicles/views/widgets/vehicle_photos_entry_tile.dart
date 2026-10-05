import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_metrics.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';
import 'package:delivery_boy/features/rider/vehicles/viewmodel/vehicle_kyc_viewmodel.dart';
import 'package:delivery_boy/features/rider/vehicles/views/widgets/vehicle_verification_widgets.dart';

/// Opens vehicle verification from the checklist's vehicle step, with the
/// photos' status at a glance.
class VehiclePhotosEntryTile extends ConsumerWidget {
  const VehiclePhotosEntryTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(vehicleVerificationProvider);
    if (view == null || view.steps.isEmpty) return const SizedBox.shrink();

    final m = KycMetrics.of(context);
    final style = VehicleStatusStyle.of(view.status, view.vehicle.kind);
    final front = view.steps.first;
    final progress = '${view.uploadedCount} of ${view.steps.length} uploaded';

    return Semantics(
      button: true,
      label: 'Vehicle photos, ${style.label}, $progress',
      excludeSemantics: true,
      child: Material(
        color: AppColors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(m.radius),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: () => context.push(AppRoutes.vehicleVerification),
          child: Padding(
            padding: EdgeInsets.all(m.gutter * 0.75),
            child: Row(
              children: [
                VehiclePhotoThumbnail(
                  size: m.iconBadge * 1.2,
                  placeholderIcon: HugeIcons.strokeRoundedCamera01,
                  localPath: front.draft?.localPath,
                  url: view.vehicle.photos[VehicleCaptureType.front],
                ),
                SizedBox(width: m.gutter * 0.75),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle photos',
                        style: TextStyle(
                          fontSize: m.bodySize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(style.icon,
                              size: m.captionSize * 1.2, color: style.color),
                          SizedBox(width: m.gutter * 0.25),
                          Flexible(
                            child: Text(
                              style.label,
                              style: TextStyle(
                                fontSize: m.captionSize,
                                fontWeight: FontWeight.w600,
                                color: style.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        progress,
                        style: TextStyle(
                          fontSize: m.captionSize,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  HugeIcons.strokeRoundedArrowRight01,
                  size: m.iconBadge * 0.4,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
