import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/order_alert_service.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/incoming_offer_logic.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_incoming_offer_dialog.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';

/// Watches the offers list and, when a new offer arrives while the rider is
/// online and the app is open, rings and raises [RiderIncomingOfferDialog].
///
/// It reacts to the list rather than to any particular transport, so it works
/// the same whether the offer arrived over the websocket, the 25 s poll, a
/// push that triggered a refresh, or the reload on app resume.
///
/// Wrap the dashboard shell in it (it is mounted for the whole session).
/// [onAccepted] runs after an offer is accepted from the dialog, so the host
/// can take the rider to their new active delivery.
class RiderIncomingOfferListener extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback onAccepted;

  const RiderIncomingOfferListener({
    super.key,
    required this.child,
    required this.onAccepted,
  });

  @override
  ConsumerState<RiderIncomingOfferListener> createState() =>
      _RiderIncomingOfferListenerState();
}

class _RiderIncomingOfferListenerState
    extends ConsumerState<RiderIncomingOfferListener>
    with WidgetsBindingObserver {
  final Set<int> _announced = {};
  bool _showing = false;

  OrderAlertService get _alert => sl<OrderAlertService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Offers may already be loaded (and waiting) by the time this mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowNext());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_alert.stop());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Offers that arrived while away are reloaded by the presence re-sync;
      // show whatever is still live once they land.
      _maybeShowNext();
    } else if (_showing) {
      // Never ring from a minimized app: the push notification covers that.
      unawaited(_alert.stop());
    }
  }

  bool get _foreground {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  RiderMeOfferModel? _nextOffer() {
    final isOnline = ref.read(
      riderMeProfileProvider.select((s) => s.profile?.isOnline ?? false),
    );
    if (!isOnline) return null;
    final fresh = offersToAnnounce(
      offers: ref.read(riderMeOffersProvider).offers,
      announcedIds: _announced,
      now: DateTime.now(),
    );
    return fresh.isEmpty ? null : fresh.first;
  }

  Future<void> _maybeShowNext() async {
    if (!mounted || _showing || !_foreground) return;
    final offer = _nextOffer();
    if (offer == null) return;

    _showing = true;
    _announced.add(offer.id);
    unawaited(_alert.start());

    final result = await showDialog<IncomingOfferResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RiderIncomingOfferDialog(offer: offer),
    );

    unawaited(_alert.stop());
    _showing = false;
    if (!mounted) return;

    switch (result) {
      case IncomingOfferResult.accepted:
        widget.onAccepted();
      case IncomingOfferResult.expired:
        // Drop the lapsed offer from the lists.
        unawaited(
          ref.read(riderMeOffersProvider.notifier).load(silent: true),
        );
      case IncomingOfferResult.declined:
      case null:
        break;
    }

    // Another offer may have queued up behind this one.
    unawaited(_maybeShowNext());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<RiderMeOfferModel>>(
      riderMeOffersProvider.select((s) => s.offers),
      (_, __) => _maybeShowNext(),
    );
    // Going online with offers already waiting.
    ref.listen<bool>(
      riderMeProfileProvider.select((s) => s.profile?.isOnline ?? false),
      (_, online) {
        if (online) _maybeShowNext();
      },
    );
    return widget.child;
  }
}
