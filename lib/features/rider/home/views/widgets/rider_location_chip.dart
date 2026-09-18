import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/app_shimmer.dart';
import 'package:delivery_boy/features/rider/location/providers/rider_location_providers.dart';

/// The rider's current address, shown under their name on the home header.
///
/// Watches [riderLocationProvider] itself rather than taking the address as a
/// constructor parameter: `_HomeHeader` already carries eight params, and
/// threading a ninth would rebuild the whole header — avatar, bell, greeting —
/// every time the address resolves. Self-watching scopes the rebuild to this
/// row and leaves the header's signature untouched.
class RiderLocationChip extends ConsumerWidget {
  const RiderLocationChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.of(context).size.width;
    final state = ref.watch(riderLocationProvider);

    // First ever launch, still locating: nothing to show but a placeholder.
    if (state.status == RiderLocationUiStatus.locating && !state.hasAddress) {
      return _LoadingBar(width: w);
    }

    // Permission and GPS failures take precedence over a cached address.
    // They are persistent and actionable, so showing yesterday's address
    // instead would leave the rider no way to put it right.
    switch (state.status) {
      case RiderLocationUiStatus.deniedForever:
        return _ActionRow(
          width: w,
          label: 'Location blocked — open settings',
          onTap: () => ref.read(riderLocationProvider.notifier).openSettings(),
        );
      case RiderLocationUiStatus.denied:
      case RiderLocationUiStatus.serviceDisabled:
        return _ActionRow(
          width: w,
          label: 'Enable location',
          onTap: () => ref.read(riderLocationProvider.notifier).refresh(),
        );
      default:
        break;
    }

    // A transient failure (timeout, error) keeps whatever address is already
    // on screen rather than flashing to "unavailable" — indoors, a fix
    // routinely times out with nothing wrong.
    if (state.hasAddress) {
      return _AddressRow(
        address: state.address!,
        width: w,
        // Dimmed while a fresh fix is in flight over a cached address.
        dimmed: state.isStale,
      );
    }

    if (state.status == RiderLocationUiStatus.error) {
      return _ActionRow(
        width: w,
        label: 'Enable location',
        onTap: () => ref.read(riderLocationProvider.notifier).refresh(),
      );
    }

    // `initial` — the bootstrap hasn't reached the location step yet.
    return _LoadingBar(width: w);
  }
}

class _LoadingBar extends StatelessWidget {
  final double width;

  const _LoadingBar({required this.width});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        width: width * 0.42,
        height: width * 0.034,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(width * 0.01),
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final String address;
  final double width;
  final bool dimmed;

  const _AddressRow({
    required this.address,
    required this.width,
    required this.dimmed,
  });

  @override
  Widget build(BuildContext context) {
    final color = dimmed
        ? AppColors.textSecondary.withValues(alpha: 0.55)
        : AppColors.textSecondary;

    return Row(
      children: [
        Icon(
          HugeIcons.strokeRoundedLocation01,
          size: width * 0.035,
          color: color,
        ),
        SizedBox(width: width * 0.012),
        // Expanded so a long formatted_address ellipsizes rather than
        // overflowing the header on a narrow screen.
        Expanded(
          child: Text(
            address,
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: (width * 0.032).clamp(11.0, 14.0),
              color: color,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final double width;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({
    required this.width,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(
            HugeIcons.strokeRoundedLocationOffline01,
            size: width * 0.035,
            color: AppColors.primary,
          ),
          SizedBox(width: width * 0.012),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: (width * 0.032).clamp(11.0, 14.0),
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: width * 0.012),
          Icon(
            HugeIcons.strokeRoundedRefresh,
            size: width * 0.03,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
