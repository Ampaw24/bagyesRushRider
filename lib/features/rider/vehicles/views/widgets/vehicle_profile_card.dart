import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_verification.dart';
import 'package:delivery_boy/features/rider/vehicles/viewmodel/vehicle_kyc_viewmodel.dart';
import 'package:delivery_boy/features/rider/vehicles/views/widgets/vehicle_verification_widgets.dart';

/// The rider's vehicle on the Profile tab: what it is, its plate and
/// ownership, and where its verification stands. Sized from the screen
/// width like the rest of the Profile tab.
///
/// Renders nothing until `/rider/me` has loaded.
class VehicleProfileCard extends ConsumerWidget {
  const VehicleProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(vehicleVerificationProvider);
    if (view == null) return const SizedBox.shrink();

    final w = MediaQuery.sizeOf(context).width;
    final vehicle = view.vehicle;
    final style = VehicleStatusStyle.of(
      view.status,
      vehicle.kind,
      rejectionReason: view.rejectionReason,
    );
    final action = switch (view.status) {
      VehicleVerificationStatus.photosRequired => 'Verify vehicle',
      VehicleVerificationStatus.actionRequired => 'Resubmit',
      _ => 'View photos',
    };

    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: w * 0.025, left: w * 0.01),
            child: Text(
              'Vehicle',
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.032,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Material(
            color: AppColors.card,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(w * 0.045),
              side: const BorderSide(color: AppColors.border, width: 0.7),
            ),
            child: InkWell(
              onTap: () => context.push(AppRoutes.vehicleVerification),
              child: Padding(
                padding: EdgeInsets.all(w * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        VehiclePhotoThumbnail(
                          size: w * 0.18,
                          placeholderIcon: vehicle.kind.icon,
                          url: vehicle.photos[VehicleCaptureType.front],
                        ),
                        SizedBox(width: w * 0.035),
                        Expanded(child: _Details(view: view, w: w)),
                      ],
                    ),
                    SizedBox(height: w * 0.03),
                    const Divider(height: 1, color: AppColors.divider),
                    SizedBox(height: w * 0.03),
                    _Status(
                      style: style,
                      action: action,
                      showMessage:
                          view.status != VehicleVerificationStatus.verified,
                      w: w,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.view, required this.w});

  final VehicleVerificationView view;
  final double w;

  @override
  Widget build(BuildContext context) {
    final vehicle = view.vehicle;
    TextStyle caption(Color color) =>
        TextStyle(fontFamily: 'Mukta', fontSize: w * 0.032, color: color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          vehicle.displayName,
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: w * 0.04,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (vehicle.details.isNotEmpty)
          Text(vehicle.details, style: caption(AppColors.textSecondary)),
        if (vehicle.plateNumber != null)
          Text(
            'Plate ${vehicle.plateNumber}',
            style: caption(AppColors.textPrimary)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        if (vehicle.ownershipLabel != null)
          Text(vehicle.ownershipLabel!, style: caption(AppColors.textHint)),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({
    required this.style,
    required this.action,
    required this.showMessage,
    required this.w,
  });

  final VehicleStatusStyle style;
  final String action;
  final bool showMessage;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(style.icon, size: w * 0.045, color: style.color),
        SizedBox(width: w * 0.02),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                style.label,
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: w * 0.035,
                  fontWeight: FontWeight.w700,
                  color: style.color,
                ),
              ),
              if (showMessage)
                Text(
                  style.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: w * 0.031,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: w * 0.02),
        Text(
          action,
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: w * 0.033,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        Icon(
          HugeIcons.strokeRoundedArrowRight01,
          size: w * 0.04,
          color: AppColors.primary,
        ),
      ],
    );
  }
}
