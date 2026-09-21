import 'package:delivery_boy/features/rider/chat/models/rider_chat_message_model.dart';

/// One cursor-paginated page of `GET /conversations/:id/messages`.
///
/// [items] arrive **newest-first**, exactly as the API returns them —
/// callers rendering a bottom-anchored thread are responsible for
/// reversing. The envelope's `cursor` object (`next`/`previous`/`has_more`)
/// is distinct from the `pagination` object the orders/offers endpoints use.
class RiderMessagesPageModel {
  const RiderMessagesPageModel({
    required this.items,
    required this.hasMore,
    this.nextCursor,
    this.previousCursor,
  });

  final List<RiderChatMessageModel> items;
  final String? nextCursor;
  final String? previousCursor;
  final bool hasMore;

  factory RiderMessagesPageModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List? ?? const [];
    final cursor = (json['cursor'] as Map?)?.cast<String, dynamic>() ?? const {};
    return RiderMessagesPageModel(
      items: itemsJson
          .map((e) =>
              RiderChatMessageModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      nextCursor: cursor['next'] as String?,
      previousCursor: cursor['previous'] as String?,
      hasMore: cursor['has_more'] as bool? ?? false,
    );
  }
}
