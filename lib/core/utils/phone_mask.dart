/// [phone] with all but its first three and last two digits hidden —
/// "0240000000" → "024•••••00", "+233504123746" → "+233•••••••46". Spacing
/// and a leading "+" are kept. A number too short to spare a head shows only
/// its last two digits.
String maskPhone(String phone) {
  final digit = RegExp(r'\d');
  final digitCount = digit.allMatches(phone).length;
  const tail = 2;
  final head = digitCount >= 8 ? 3 : 0;

  var seen = 0;
  final masked = StringBuffer();
  for (final unit in phone.split('')) {
    if (!digit.hasMatch(unit)) {
      masked.write(unit);
      continue;
    }
    final keep = seen < head || seen >= digitCount - tail;
    masked.write(keep ? unit : '•');
    seen++;
  }
  return masked.toString();
}
