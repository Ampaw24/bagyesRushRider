import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';

/// What/who a rider is reporting. Unlike the customer/vendor app, a rider
/// never reports another rider — the eligible categories here are the ones
/// a rider actually encounters mid-delivery.
enum RiderReportTargetType {
  vendor,
  customer,
  orderIssue,
  general;

  /// The wire value for `POST /rider/me/reports`. Mirrored from the
  /// customer/vendor contract: the backend's `target_type` column only
  /// accepts `"order_issue"` or `"general"` — which category is actually
  /// being reported travels separately via `target_name`/`order_id`.
  String get apiValue =>
      this == RiderReportTargetType.general ? 'general' : 'order_issue';

  static RiderReportTargetType fromString(String value) {
    switch (value) {
      case 'vendor':
        return RiderReportTargetType.vendor;
      case 'customer':
        return RiderReportTargetType.customer;
      case 'order_issue':
        return RiderReportTargetType.orderIssue;
      default:
        return RiderReportTargetType.general;
    }
  }

  /// Whether this category benefits from linking a specific past order.
  /// A rider has no vendor id/name or customer id anywhere except on an
  /// order, so "which order is this about?" doubles as the target picker
  /// for every category except [general].
  bool get needsOrderLink => this != RiderReportTargetType.general;
}

enum RiderReportStatus {
  pending('Pending', AppColors.warning),
  inReview('In Review', AppColors.info),
  resolved('Resolved', AppColors.success),
  dismissed('Dismissed', AppColors.textHint);

  final String label;
  final Color color;
  const RiderReportStatus(this.label, this.color);

  /// Falls back to [pending] for an unrecognized value rather than
  /// throwing — this endpoint hasn't been verified against a live
  /// response yet.
  static RiderReportStatus fromString(String value) {
    switch (value) {
      case 'in_review':
      case 'reviewing':
        return RiderReportStatus.inReview;
      case 'resolved':
        return RiderReportStatus.resolved;
      case 'dismissed':
      case 'rejected':
        return RiderReportStatus.dismissed;
      default:
        return RiderReportStatus.pending;
    }
  }
}

class RiderReportReasonOption extends Equatable {
  final String code;
  final String label;

  const RiderReportReasonOption({required this.code, required this.label});

  factory RiderReportReasonOption.fromJson(Map<String, dynamic> json) =>
      RiderReportReasonOption(
        code: json['code'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );

  @override
  List<Object?> get props => [code, label];
}

/// Reason options for the "what went wrong?" step, grouped by
/// [RiderReportTargetType] — `GET /reports/reasons`. The response also
/// carries a `rider` group (for when a customer/vendor reports a rider),
/// which this app has no use for and doesn't parse.
class RiderReportReasonCatalog extends Equatable {
  final List<RiderReportReasonOption> vendor;
  final List<RiderReportReasonOption> customer;
  final List<RiderReportReasonOption> orderIssue;
  final List<RiderReportReasonOption> general;

  const RiderReportReasonCatalog({
    this.vendor = const [],
    this.customer = const [],
    this.orderIssue = const [],
    this.general = const [],
  });

  factory RiderReportReasonCatalog.fromJson(Map<String, dynamic> json) {
    List<RiderReportReasonOption> parse(String key) => (json[key]
                as List<dynamic>? ??
            const [])
        .map((e) => RiderReportReasonOption.fromJson(e as Map<String, dynamic>))
        .toList();
    return RiderReportReasonCatalog(
      vendor: parse('vendor'),
      customer: parse('customer'),
      orderIssue: parse('order_issue'),
      general: parse('general'),
    );
  }

  List<RiderReportReasonOption> forTargetType(RiderReportTargetType type) =>
      switch (type) {
        RiderReportTargetType.vendor => vendor,
        RiderReportTargetType.customer => customer,
        RiderReportTargetType.orderIssue => orderIssue,
        RiderReportTargetType.general => general,
      };

  @override
  List<Object?> get props => [vendor, customer, orderIssue, general];
}

/// A rider-filed report — `GET|POST /rider/me/reports`,
/// `GET /rider/me/reports/:id`.
class RiderReportModel extends Equatable {
  final int id;
  final RiderReportTargetType targetType;

  /// The delivery this report relates to, when there is one. A rider has
  /// no other stable id for the vendor/customer involved, so this is
  /// usually the only link back to who/what is being reported.
  final int? orderId;
  final String targetName;
  final String? targetImageUrl;
  final String? targetPhone;

  final String reasonCode;
  final String reasonLabel;
  final String description;
  final List<String> attachmentUrls;
  final RiderReportStatus status;
  final DateTime createdAt;
  final String? resolutionNote;

  const RiderReportModel({
    required this.id,
    required this.targetType,
    this.orderId,
    required this.targetName,
    this.targetImageUrl,
    this.targetPhone,
    required this.reasonCode,
    required this.reasonLabel,
    required this.description,
    this.attachmentUrls = const [],
    required this.status,
    required this.createdAt,
    this.resolutionNote,
  });

  factory RiderReportModel.fromJson(Map<String, dynamic> json) =>
      RiderReportModel(
        id: _int(json['id']) ?? 0,
        targetType: RiderReportTargetType.fromString(
          json['target_type'] as String? ?? '',
        ),
        orderId: _int(json['order_id']),
        targetName: json['target_name'] as String? ?? '',
        targetImageUrl: json['target_image_url'] as String?,
        targetPhone: json['target_phone'] as String?,
        reasonCode: json['reason_code'] as String? ?? '',
        reasonLabel: json['reason_label'] as String? ?? '',
        description: json['description'] as String? ?? '',
        attachmentUrls: (json['attachment_urls'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        status: RiderReportStatus.fromString(json['status'] as String? ?? ''),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        resolutionNote: json['resolution_note'] as String?,
      );

  @override
  List<Object?> get props => [
        id,
        targetType,
        orderId,
        targetName,
        targetImageUrl,
        targetPhone,
        reasonCode,
        reasonLabel,
        description,
        attachmentUrls,
        status,
        createdAt,
        resolutionNote,
      ];
}

int? _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('${value ?? ''}');
