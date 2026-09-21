import 'package:equatable/equatable.dart';

/// Where a banner tap should go — `{"type": "url" | "none", "value": ...}`.
/// Only `url` is actionable; every other type (including `none`, and any
/// future type this app doesn't recognise yet) is treated as non-interactive
/// rather than guessed at.
class RiderBannerLinkModel extends Equatable {
  final String type;
  final String? value;

  const RiderBannerLinkModel({this.type = 'none', this.value});

  factory RiderBannerLinkModel.fromJson(Map<String, dynamic> json) {
    return RiderBannerLinkModel(
      type: json['type'] as String? ?? 'none',
      value: json['value'] as String?,
    );
  }

  @override
  List<Object?> get props => [type, value];
}

/// A home-screen promotional banner — `GET /banners` (public, shared with
/// the customer/vendor app; the repository filters to `placement == 'home'`).
class RiderBannerModel extends Equatable {
  final int id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final String placement;
  final int displayOrder;
  final RiderBannerLinkModel link;

  const RiderBannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    this.placement = 'home',
    this.displayOrder = 0,
    this.link = const RiderBannerLinkModel(),
  });

  /// Falls back to [description] when [subtitle] is blank — most banners
  /// only fill in one of the two.
  String? get displaySubtitle =>
      (subtitle?.isNotEmpty ?? false) ? subtitle : description;

  factory RiderBannerModel.fromJson(Map<String, dynamic> json) {
    return RiderBannerModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      placement: json['placement'] as String? ?? 'home',
      displayOrder: json['display_order'] as int? ?? 0,
      link: json['link'] is Map<String, dynamic>
          ? RiderBannerLinkModel.fromJson(json['link'] as Map<String, dynamic>)
          : const RiderBannerLinkModel(),
    );
  }

  @override
  List<Object?> get props => [id, title, imageUrl, placement, displayOrder];
}
