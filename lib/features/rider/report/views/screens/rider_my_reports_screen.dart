import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/animated_list_item.dart';
import 'package:delivery_boy/core/widgets/shimmer_list_placeholder.dart';
import 'package:delivery_boy/features/rider/report/models/rider_report_model.dart';
import 'package:delivery_boy/features/rider/report/providers/rider_my_reports_providers.dart';
import 'package:delivery_boy/features/rider/report/views/widgets/rider_report_card.dart';

enum _ReportFilter { open, closed, all }

bool _isOpen(RiderReportModel r) =>
    r.status == RiderReportStatus.pending ||
    r.status == RiderReportStatus.inReview;

/// "My Reports" — a rider's history of filed reports, with the entry point
/// to start a new one. Mirrors the wallet transactions screen's
/// loading/empty/error shape (`ShimmerListPlaceholder`/`AnimatedListItem`).
class RiderMyReportsScreen extends ConsumerStatefulWidget {
  const RiderMyReportsScreen({super.key});

  @override
  ConsumerState<RiderMyReportsScreen> createState() =>
      _RiderMyReportsScreenState();
}

class _RiderMyReportsScreenState extends ConsumerState<RiderMyReportsScreen> {
  _ReportFilter _filter = _ReportFilter.open;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderMyReportsProvider.notifier).load();
    });
  }

  Future<void> _startNewReport() async {
    final submitted = await context.push<bool>(AppRoutes.reportNew);
    if (submitted == true) {
      ref.read(riderMyReportsProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final state = ref.watch(riderMyReportsProvider);
    final notifier = ref.read(riderMyReportsProvider.notifier);

    final filtered = switch (_filter) {
      _ReportFilter.open => state.reports.where(_isOpen).toList(),
      _ReportFilter.closed => state.reports.where((r) => !_isOpen(r)).toList(),
      _ReportFilter.all => state.reports,
    };

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('My Reports'),
        backgroundColor: AppColors.scaffold,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewReport,
        icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedFlag02, color: Colors.white),
        label: const Text('Report a Problem'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding:
                  EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.02),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _FilterChips(
                  filter: _filter,
                  onSelect: (f) => setState(() => _filter = f),
                ),
              ),
            ),
            Expanded(
              child: switch (state.status) {
                RiderMyReportsStatus.initial ||
                RiderMyReportsStatus.loading =>
                  const ShimmerListPlaceholder(itemCount: 6, itemHeight: 90),
                RiderMyReportsStatus.error => _ErrorState(
                    w: w,
                    message: state.errorMessage ?? 'Something went wrong.',
                    onRetry: notifier.load,
                  ),
                RiderMyReportsStatus.loaded => filtered.isEmpty
                    ? _EmptyState(w: w, onReport: _startNewReport)
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: notifier.load,
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                              w * 0.05, 0, w * 0.05, w * 0.2),
                          itemCount: filtered.length,
                          separatorBuilder: (context, i) =>
                              SizedBox(height: w * 0.03),
                          itemBuilder: (context, i) => AnimatedListItem(
                            index: i,
                            child: RiderReportCard(
                              report: filtered[i],
                              onTap: () => context
                                  .push(AppRoutes.reportDetail(filtered[i].id)),
                            ),
                          ),
                        ),
                      ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final _ReportFilter filter;
  final ValueChanged<_ReportFilter> onSelect;

  const _FilterChips({required this.filter, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Wrap(
      spacing: w * 0.02,
      children: _ReportFilter.values.map((f) {
        final selected = filter == f;
        final label = switch (f) {
          _ReportFilter.open => 'Open',
          _ReportFilter.closed => 'Closed',
          _ReportFilter.all => 'All',
        };
        return GestureDetector(
          onTap: () => onSelect(f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.015),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: w * 0.031,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final double w;
  final VoidCallback onReport;

  const _EmptyState({required this.w, required this.onReport});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
                icon: HugeIcons.strokeRoundedFlag02,
                size: w * 0.16,
                color: AppColors.textHint),
            SizedBox(height: w * 0.04),
            Text(
              'No reports yet',
              style: TextStyle(
                fontSize: w * 0.044,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              'Run into a problem with a vendor, a customer, or an order? Let us know.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: w * 0.033,
                  color: AppColors.textSecondary,
                  height: 1.4),
            ),
            SizedBox(height: w * 0.05),
            ElevatedButton(
                onPressed: onReport, child: const Text('Report a Problem')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final double w;
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState(
      {required this.w, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              size: w * 0.14,
              color: AppColors.error,
            ),
            SizedBox(height: w * 0.04),
            Text(
              "Couldn't load your reports",
              style: TextStyle(
                fontSize: w * 0.042,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: w * 0.032, color: AppColors.textSecondary)),
            SizedBox(height: w * 0.05),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
