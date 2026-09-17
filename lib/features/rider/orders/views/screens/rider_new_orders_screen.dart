import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/animated_list_item.dart';
import 'package:delivery_boy/core/widgets/app_toast.dart';
import 'package:delivery_boy/core/widgets/shimmer_list_placeholder.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/reason_input_sheet.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_me_offer_card.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_me_offer_detail_sheet.dart';
import 'package:hugeicons/hugeicons.dart';

/// Push notifications are fully disabled app-wide (Firebase itself isn't
/// initialized in main.dart), so this periodic poll is the stopgap for a
/// rider learning about a new offer without pull-to-refreshing manually.
const _pollInterval = Duration(seconds: 25);

class RiderNewOrdersScreen extends ConsumerStatefulWidget {
  const RiderNewOrdersScreen({super.key});

  @override
  ConsumerState<RiderNewOrdersScreen> createState() =>
      _RiderNewOrdersScreenState();
}

class _RiderNewOrdersScreenState extends ConsumerState<RiderNewOrdersScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderMeOffersProvider.notifier).load();
      _pollTimer = Timer.periodic(
        _pollInterval,
        (_) => ref.read(riderMeOffersProvider.notifier).load(silent: true),
      );
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _openDetailSheet(RiderMeOfferModel offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RiderMeOfferDetailSheet(offer: offer),
    );
  }

  void _showDeclineSheet(RiderMeOfferModel offer) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReasonInputSheet(
        title: 'Reason for Declining',
        submitLabel: 'Submit',
        onSubmit: (reason) => ref
            .read(riderMeOffersProvider.notifier)
            .decline(offer.id, reason: reason.isEmpty ? null : reason),
      ),
    );
  }

  Future<void> _quickAccept(RiderMeOfferModel offer) async {
    final ok = await ref.read(riderMeOffersProvider.notifier).accept(offer.id);
    if (ok && mounted) {
      HapticFeedback.mediumImpact();
      AppToast.show(
        context,
        isSuccess: true,
        title: 'Order Accepted',
        subtitle: 'This delivery has been added to your active orders.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderMeOffersProvider);

    // The offers list poll (every 25s) used to surface a failed
    // GET /rider/me/offers as a snackbar on every retry — noisy and not
    // actionable for the rider, so a failed load just falls back silently to
    // the last known list/empty state instead of interrupting them.

    if (state.status == RiderMeOrdersStatus.loading ||
        state.status == RiderMeOrdersStatus.initial) {
      return const ShimmerListPlaceholder(itemCount: 4, itemHeight: 110);
    }

    if (state.offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(HugeIcons.strokeRoundedShoppingCart01,
                  color: AppColors.primary.withValues(alpha: 0.6), size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'No New Orders',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New delivery requests will appear here.',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(riderMeOffersProvider.notifier).load(),
      child: ListView.builder(
        itemCount: state.offers.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, i) {
          final offer = state.offers[i];
          return AnimatedListItem(
            index: i,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Slidable(
                key: ValueKey(offer.id),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.5,
                  children: [
                    SlidableAction(
                      onPressed: (_) => _quickAccept(offer),
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                      label: 'Accept',
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12)),
                    ),
                    SlidableAction(
                      onPressed: (_) => _showDeclineSheet(offer),
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      icon: HugeIcons.strokeRoundedCancelCircle,
                      label: 'Decline',
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(12)),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => _openDetailSheet(offer),
                  child: RiderMeOfferCard(
                    offer: offer,
                    actionButton: GestureDetector(
                      onTap: () => _openDetailSheet(offer),
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFFCA445D)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'View',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
