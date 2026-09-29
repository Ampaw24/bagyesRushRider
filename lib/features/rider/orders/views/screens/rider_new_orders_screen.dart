import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/animated_list_item.dart';
import 'package:delivery_boy/core/widgets/app_toast.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/core/widgets/shimmer_list_placeholder.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/reason_input_sheet.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_me_offer_card.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_me_offer_detail_sheet.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_orders_empty_state.dart';
import 'package:hugeicons/hugeicons.dart';

/// Position of the Active tab in the Orders page's Active / New / History
/// bar — where an accepted offer continues.
const kRiderActiveOrdersTabIndex = 0;

/// Delivery offers awaiting the rider's decision. The offers list itself is
/// loaded and polled by the Orders page (see `_OrdersTab`), so offers keep
/// arriving — and the tab badge stays current — while another tab is open.
class RiderNewOrdersScreen extends ConsumerStatefulWidget {
  const RiderNewOrdersScreen({super.key});

  @override
  ConsumerState<RiderNewOrdersScreen> createState() =>
      _RiderNewOrdersScreenState();
}

class _RiderNewOrdersScreenState extends ConsumerState<RiderNewOrdersScreen> {
  /// The offer whose accept request is in flight, for its button spinner.
  int? _acceptingId;

  Future<void> _openDetailSheet(RiderMeOfferModel offer) async {
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RiderMeOfferDetailSheet(offer: offer),
    );
    if (accepted == true && mounted) _onAccepted();
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

  /// Moves the rider straight to the Active tab, where the accepted
  /// delivery is waiting with its first step ("Arrived at Pickup") —
  /// otherwise they're left on an offers list the order just left.
  void _onAccepted() {
    AppToast.show(
      context,
      isSuccess: true,
      title: 'Order Accepted',
      subtitle: "Head to the pickup, then tap 'Arrived at Pickup'.",
    );
    ref.read(riderMeOrdersProvider.notifier).load(filter: 'active');
    DefaultTabController.maybeOf(context)
        ?.animateTo(kRiderActiveOrdersTabIndex);
  }

  Future<void> _accept(RiderMeOfferModel offer) async {
    if (_acceptingId != null) return;
    setState(() => _acceptingId = offer.id);
    final ok = await ref.read(riderMeOffersProvider.notifier).accept(offer.id);
    if (!mounted) return;
    setState(() => _acceptingId = null);
    if (ok) {
      HapticFeedback.mediumImpact();
      _onAccepted();
    } else {
      CustomDialog.showError(
        context: context,
        title: "Couldn't Accept Order",
        subtitle: ref.read(riderMeOffersProvider).actionMessage ??
            'Could not accept this offer',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderMeOffersProvider);

    // A failed poll falls back silently to the last known list rather than
    // interrupting the rider every 25s with an error they can't act on.

    if (state.status == RiderMeOrdersStatus.loading ||
        state.status == RiderMeOrdersStatus.initial) {
      return const ShimmerListPlaceholder(itemCount: 4, itemHeight: 110);
    }

    Future<void> reload() => ref.read(riderMeOffersProvider.notifier).load();

    if (state.offers.isEmpty) {
      return RiderOrdersEmptyState(
        icon: HugeIcons.strokeRoundedShoppingCart01,
        title: 'No new orders',
        message: 'New delivery requests will appear here. Stay online to '
            'receive them.',
        onRefresh: reload,
      );
    }

    final w = MediaQuery.sizeOf(context).width;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: reload,
      child: ListView.separated(
        itemCount: state.offers.length,
        padding: EdgeInsets.all(w * 0.04),
        physics: const AlwaysScrollableScrollPhysics(),
        separatorBuilder: (_, __) => SizedBox(height: w * 0.03),
        itemBuilder: (_, i) {
          final offer = state.offers[i];
          final busy = _acceptingId != null;
          return AnimatedListItem(
            index: i,
            child: RiderMeOfferCard(
              offer: offer,
              onTap: () => _openDetailSheet(offer),
              isAccepting: _acceptingId == offer.id,
              onAccept: busy ? null : () => _accept(offer),
              onDecline: busy ? null : () => _showDeclineSheet(offer),
            ),
          );
        },
      ),
    );
  }
}
