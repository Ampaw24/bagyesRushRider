import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';

// ── Colors (mapped to the canonical AppColors palette) ───────────────────────
Color scaffoldBgColor = AppColors.scaffold;
Color primaryColor = AppColors.primary;
Color darkPrimaryColor = AppColors.primaryDark;
Color greyColor = AppColors.textSecondary;
Color whiteColor = AppColors.onPrimary;
Color blackColor = AppColors.textPrimary;
Color lightGreyColor = AppColors.border;

// ── Spacing ───────────────────────────────────────────────────────────────────
double fixPadding = 10.0;
SizedBox heightSpace = const SizedBox(height: 10.0);
SizedBox widthSpace = const SizedBox(width: 10.0);

// ── Text styles (Mukta — matches AppTheme.light fontFamily) ──────────────────
TextStyle bottomBarItemStyle = TextStyle(
  color: greyColor,
  fontSize: 12.0,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.w500,
);

TextStyle bigHeadingStyle = TextStyle(
  fontSize: 22.0,
  color: blackColor,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.w600,
);

TextStyle bigWhiteHeadingStyle = TextStyle(
  fontSize: 24.0,
  color: whiteColor,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.w600,
);

TextStyle headingStyle = TextStyle(
  fontSize: 18.0,
  color: blackColor,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.w500,
);

TextStyle greyHeadingStyle = TextStyle(
  fontSize: 16.0,
  color: greyColor,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.w500,
);

TextStyle blueTextStyle = const TextStyle(
  fontSize: 18.0,
  color: AppColors.info,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.w400,
);

TextStyle whiteHeadingStyle = TextStyle(
  fontSize: 22.0,
  color: whiteColor,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.w500,
);

TextStyle whiteSubHeadingStyle = TextStyle(
  fontSize: 14.0,
  color: whiteColor,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.normal,
);

TextStyle wbuttonWhiteTextStyle = TextStyle(
  fontSize: 16.0,
  color: whiteColor,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.w500,
);

TextStyle buttonBlackTextStyle = TextStyle(
  fontSize: 16.0,
  color: blackColor,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.w500,
);

TextStyle moreStyle = TextStyle(
  fontSize: 14.0,
  color: primaryColor,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.w500,
);

TextStyle priceStyle = TextStyle(
  fontSize: 18.0,
  color: primaryColor,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.bold,
);

TextStyle lightGreyStyle = TextStyle(
  fontSize: 15.0,
  color: AppColors.textHint,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.w500,
);

// ── List item styles ──────────────────────────────────────────────────────────
TextStyle listItemTitleStyle = TextStyle(
  fontSize: 15.0,
  color: blackColor,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.w500,
);

TextStyle listItemSubTitleStyle = TextStyle(
  fontSize: 14.0,
  color: greyColor,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.normal,
);

// ── AppBar styles ─────────────────────────────────────────────────────────────
TextStyle appbarHeadingStyle = const TextStyle(
  color: AppColors.primaryDark,
  fontSize: 14.0,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.w500,
);

TextStyle appbarSubHeadingStyle = TextStyle(
  color: whiteColor,
  fontSize: 13.0,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.w500,
);

// ── Search styles ─────────────────────────────────────────────────────────────
TextStyle searchTextStyle = const TextStyle(
  color: AppColors.textHint,
  fontSize: 16.0,
  fontFamily: 'Mukta',
  fontWeight: FontWeight.w500,
);
