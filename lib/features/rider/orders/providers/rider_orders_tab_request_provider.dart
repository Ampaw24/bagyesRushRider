import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A one-shot request to switch the Orders page to a given sub-tab (Active /
/// New / History). The page owns its `TabController`, so anything outside it —
/// e.g. the incoming-offer dialog, once an offer is accepted — asks through
/// here; the page consumes the request and resets it to null.
final riderOrdersTabRequestProvider = StateProvider<int?>((ref) => null);
