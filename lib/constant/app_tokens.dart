import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

abstract final class AppFonts {
  static const String display = 'Outfit';
  static const String body = 'Inter';
}

abstract final class AppRadius {
  static const double input = 12;
  static const double card = 20;
  static const double sheet = 24;
  static const double snackbar = 16;
}

abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D087A4B), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(
      color: Color(0x0F11231B),
      blurRadius: 6,
      spreadRadius: -1,
      offset: Offset(0, 2),
    ),
  ];
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x1F087A4B),
      blurRadius: 32,
      spreadRadius: -4,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x0F11231B),
      blurRadius: 12,
      spreadRadius: -2,
      offset: Offset(0, 4),
    ),
  ];
}

abstract final class AppMotion {
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration entrance = Duration(milliseconds: 700);
  static const Duration intro = Duration(milliseconds: 2000);
  static const Duration ambient = Duration(milliseconds: 1200);
  static const Duration stagger = Duration(milliseconds: 70);
  static const Curve outExpo = Cubic(0.16, 1, 0.3, 1);
  static const Curve inOutQuart = Cubic(0.76, 0, 0.24, 1);
  static const Curve spring = Curves.easeOutBack;
}
