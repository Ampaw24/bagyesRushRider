import 'package:flutter/widgets.dart';

/// Avatar initials: the first character of the first and last words —
/// "Kofi Asante" → "KA", "Ama" → "A" — or [fallback] for a blank name.
///
/// Takes whole user-perceived characters, never `word[0]`: that is a single
/// UTF-16 code unit, so a name starting with an emoji or a styled letter
/// ("😊 Ama", "𝐀𝐦𝐚") yields half a surrogate pair, and Flutter's text layout
/// throws "string is not well-formed UTF-16".
String initialsOf(String? name, {String fallback = '?'}) {
  final words = (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return fallback;
  final first = words.first.characters.first;
  final last = words.length > 1 ? words.last.characters.first : '';
  return (first + last).toUpperCase();
}
