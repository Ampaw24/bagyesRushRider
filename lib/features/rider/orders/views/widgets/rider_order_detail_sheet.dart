import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/drag_handle.dart';
import 'package:delivery_boy/core/widgets/status_badge.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_order_model.dart';

/// Trip status chain — order matters.
const _statusChain = [
  'accepted',
  'heading_to_pickup',
  'arrived_at_pickup',
  'picked_up',
  'en_route',
  'delivered',
];

const _statusLabels = {
  'accepted': 'Accepted',
  'heading_to_pickup': 'Heading',
  'arrived_at_pickup': 'Arrived',
  'picked_up': 'Picked Up',
  'en_route': 'En Route',
  'delivered': 'Delivered',
};

class RiderOrderDetailSheet extends StatelessWidget {
  final RiderOrderModel order;
  final Widget actionButton;

  const RiderOrderDetailSheet({
    super.key,
    required this.order,
    required this.actionButton,
  });

  int get _currentStep {
    final idx = _statusChain.indexOf(order.status ?? '');
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollCtrl,
            children: [
              const DragHandle(),

              // ── Gradient header ──────────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFCA445D)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.orderId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.paymentMode,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: _statusLabels[order.status] ?? 'Pending',
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Trip status stepper ──────────────────────────────────────
              if (order.status != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TripStepper(currentStep: _currentStep),
                ),
                const SizedBox(height: 8),
              ],

              // ── Package image ────────────────────────────────────────────
              if (order.image != null && order.image!.isNotEmpty)
                _card(
                  title: 'Package Image',
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(order.image!,
                          fit: BoxFit.contain, height: 140),
                    ),
                  ),
                ),

              // ── Order details ────────────────────────────────────────────
              _card(
                title: 'Order',
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _row('Package Type', order.packageType ?? '-'),
                      const SizedBox(height: 8),
                      _row('Weight', order.weight ?? '-'),
                      const SizedBox(height: 8),
                      _row('Payment', 'GHS ${order.amount}'),
                      const SizedBox(height: 8),
                      _row('Charges', 'GHS ${order.charges}'),
                      const Divider(height: 20),
                      _row(
                        'Total',
                        'GHS ${order.totalAmount}',
                        valueStyle: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Location ─────────────────────────────────────────────────
              _card(
                title: 'Location',
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _locationRow(
                        icon: Icons.radio_button_checked,
                        iconColor: Colors.green,
                        label: 'Pickup',
                        value: order.pickUpLocation,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 11),
                        child: Column(
                          children: List.generate(
                            3,
                            (_) => Container(
                              width: 2,
                              height: 5,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                      _locationRow(
                        icon: Icons.location_on,
                        iconColor: AppColors.primary,
                        label: 'Delivery',
                        value: order.deliveryLocation,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Customer ─────────────────────────────────────────────────
              _card(
                title: 'Customer',
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _row('Name', order.customer?.name ?? '-'),
                      const SizedBox(height: 10),
                      // Tappable phone row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Phone',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _callCustomer(order.customer?.phone),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  order.customer?.phone ?? '-',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.call_outlined,
                                    size: 16, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Payment ──────────────────────────────────────────────────
              _card(
                title: 'Payment',
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _row('Method', order.paymentMode),
                      const SizedBox(height: 8),
                      _row('Order Date', order.formattedDate),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: actionButton,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ── Helper widgets ──────────────────────────────────────────────────────────

  Widget _card({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            spreadRadius: 0,
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: valueStyle ??
                const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }

  Widget _locationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ── Trip Stepper ──────────────────────────────────────────────────────────────

class _TripStepper extends StatelessWidget {
  final int currentStep;

  const _TripStepper({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(_statusChain.length * 2 - 1, (i) {
              if (i.isOdd) {
                // Connector line
                final stepIdx = i ~/ 2;
                final isCompleted = stepIdx < currentStep;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? AppColors.success
                        : Colors.grey.shade300,
                  ),
                );
              }
              final stepIdx = i ~/ 2;
              final isCompleted = stepIdx < currentStep;
              final isCurrent = stepIdx == currentStep;
              return _StepCircle(
                isCompleted: isCompleted,
                isCurrent: isCurrent,
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _statusChain
                .asMap()
                .entries
                .map((e) => _StepLabel(
                      label: _statusLabels[e.value] ?? '',
                      isCompleted: e.key < currentStep,
                      isCurrent: e.key == currentStep,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StepCircle extends StatefulWidget {
  final bool isCompleted;
  final bool isCurrent;

  const _StepCircle({required this.isCompleted, required this.isCurrent});

  @override
  State<_StepCircle> createState() => _StepCircleState();
}

class _StepCircleState extends State<_StepCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale =
        Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isCurrent) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCurrent) {
      return ScaleTransition(
        scale: _scale,
        child: _circle(),
      );
    }
    return _circle();
  }

  Widget _circle() {
    if (widget.isCompleted) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 13),
      );
    }
    if (widget.isCurrent) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Center(
          child: CircleAvatar(
            radius: 5,
            backgroundColor: Colors.white,
          ),
        ),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String label;
  final bool isCompleted;
  final bool isCurrent;

  const _StepLabel({
    required this.label,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 9,
          fontWeight:
              isCurrent ? FontWeight.w700 : FontWeight.w400,
          color: isCurrent
              ? AppColors.primary
              : isCompleted
                  ? AppColors.success
                  : Colors.grey.shade400,
        ),
      ),
    );
  }
}
