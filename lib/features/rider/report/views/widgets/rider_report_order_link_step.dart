import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/report/models/rider_report_model.dart';

/// The fields this step derives once an order is picked — a rider has no
/// vendor/customer id anywhere except on an order, so this doubles as the
/// "who/what is this about?" identification for every category that needs
/// one (see [RiderReportTargetType.needsOrderLink]).
class RiderReportOrderTarget {
  final int orderId;
  final String name;
  final String subtitle;
  final String? phone;

  const RiderReportOrderTarget({
    required this.orderId,
    required this.name,
    required this.subtitle,
    this.phone,
  });

  factory RiderReportOrderTarget.from(
    RiderMeOrderModel order,
    RiderReportTargetType type,
  ) {
    final reference = order.reference ?? 'Order #${order.id}';
    return switch (type) {
      RiderReportTargetType.customer => RiderReportOrderTarget(
          orderId: order.id,
          name: order.customerName?.isNotEmpty == true
              ? order.customerName!
              : 'Customer',
          subtitle: order.dropoffAddress ?? reference,
          phone: order.customerPhone,
        ),
      RiderReportTargetType.vendor => RiderReportOrderTarget(
          orderId: order.id,
          name: order.pickupAddress?.isNotEmpty == true
              ? order.pickupAddress!
              : 'Vendor',
          subtitle: reference,
        ),
      _ => RiderReportOrderTarget(
          orderId: order.id,
          name: reference,
          subtitle: order.pickupAddress ?? order.dropoffAddress ?? '',
        ),
    };
  }
}

/// Step 2 — "Which delivery is this about?" A rider has no standalone
/// vendor/customer record, only orders, so this doubles as the target
/// picker for every category that benefits from one. Skippable: the order
/// link is a nice-to-have for support, not required to file the report.
class RiderReportOrderLinkStep extends StatefulWidget {
  final RiderReportTargetType targetType;
  final List<RiderMeOrderModel> orders;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<RiderReportOrderTarget> onSelect;
  final VoidCallback onSkip;

  const RiderReportOrderLinkStep({
    super.key,
    required this.targetType,
    required this.orders,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onSelect,
    required this.onSkip,
  });

  @override
  State<RiderReportOrderLinkStep> createState() =>
      _RiderReportOrderLinkStepState();
}

class _RiderReportOrderLinkStepState extends State<RiderReportOrderLinkStep> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _heading => switch (widget.targetType) {
        RiderReportTargetType.customer =>
          'Which delivery was this customer on?',
        RiderReportTargetType.vendor => 'Which pickup was this vendor for?',
        _ => 'Which order is this about?',
      };

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final targets = widget.orders
        .map((o) => RiderReportOrderTarget.from(o, widget.targetType))
        .where((t) =>
            _query.isEmpty ||
            t.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, 0),
          child: Text(
            _heading,
            style: TextStyle(
              fontSize: w * 0.052,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: w * 0.02),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Not sure? You can skip this and still file the report.",
                  style: TextStyle(
                      fontSize: w * 0.032, color: AppColors.textSecondary),
                ),
              ),
              TextButton(onPressed: widget.onSkip, child: const Text('Skip')),
            ],
          ),
        ),
        SizedBox(height: w * 0.02),
        if (widget.orders.length > 5)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search your deliveries',
                prefixIcon: const Icon(HugeIcons.strokeRoundedSearch01),
              ),
            ),
          ),
        SizedBox(height: w * 0.03),
        Expanded(
          child: widget.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : widget.errorMessage != null
                  ? _MessageState(
                      w: w,
                      title: "Couldn't load your deliveries",
                      message: widget.errorMessage!,
                      actionLabel: 'Retry',
                      onAction: widget.onRetry,
                    )
                  : targets.isEmpty
                      ? _MessageState(
                          w: w,
                          title: 'Nothing to show here yet',
                          message: 'Your recent deliveries will show up here.',
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                              w * 0.05, 0, w * 0.05, w * 0.06),
                          itemCount: targets.length,
                          separatorBuilder: (context, i) =>
                              SizedBox(height: w * 0.03),
                          itemBuilder: (context, i) => _OrderTile(
                            target: targets[i],
                            w: w,
                            onTap: () => widget.onSelect(targets[i]),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _OrderTile extends StatelessWidget {
  final RiderReportOrderTarget target;
  final double w;
  final VoidCallback onTap;

  const _OrderTile(
      {required this.target, required this.w, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(w * 0.035),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(w * 0.035),
        child: Container(
          padding: EdgeInsets.all(w * 0.035),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(w * 0.035),
            border: Border.all(color: AppColors.border, width: 0.7),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.03),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedPackage,
                  color: AppColors.primary,
                  size: w * 0.05,
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.name,
                      style: TextStyle(
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: w * 0.006),
                    Text(
                      target.subtitle,
                      style: TextStyle(
                          fontSize: w * 0.031, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: w * 0.02),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.textHint,
                size: w * 0.038,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final double w;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.w,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedSearchRemove,
              size: w * 0.14,
              color: AppColors.textHint,
            ),
            SizedBox(height: w * 0.04),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.04,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: w * 0.032, color: AppColors.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: w * 0.04),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
