import 'package:flutter/material.dart';
import 'app_theme.dart';

// ── Colors (aligned with AppColors but kept for backward compat) ──
const Color scaffoldBgColor = AppColors.scaffold;
const Color primaryColor = AppColors.primary;
const Color greyColor = AppColors.textSecondary;
const Color whiteColor = Colors.white;
const Color blackColor = AppColors.textPrimary;
Color lightGreyColor = AppColors.border;
Color lightPrimaryColor = AppColors.primary.withValues(alpha: 0.1);
const Color whiteBackgroundColor = AppColors.scaffold;

// ── Spacing ──
const double fixPadding = 10.0;
const double buttonHeight = 70;

const SizedBox heightSpace = SizedBox(height: 10.0);
const SizedBox widthSpace = SizedBox(width: 10.0);

// ── Text Styles ──
const TextStyle splashBigTextStyle = TextStyle(
  color: AppColors.primary,
  fontSize: 40.0,
  fontFamily: 'Pacifico',
);

const TextStyle bottomBarItemStyle = TextStyle(
  color: AppColors.primary,
  fontSize: 11.0,
  fontWeight: FontWeight.w500,
);

const TextStyle appBarTextStyle = TextStyle(
  color: AppColors.primary,
  fontSize: 18.0,
  fontWeight: FontWeight.w500,
);

const TextStyle appBarBlackTextStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 18.0,
  fontWeight: FontWeight.w500,
);

const TextStyle blackHeadingTextStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 17.0,
  height: 1.3,
  fontWeight: FontWeight.w500,
);

const TextStyle blackSmallTextStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 15.0,
  height: 1.3,
);

const TextStyle blackSmallBoldTextStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 15.0,
  fontWeight: FontWeight.w500,
);

const TextStyle blackLargeTextStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 20.0,
  height: 1.3,
);

const TextStyle blackExtraLargeTextStyle = TextStyle(
  color: AppColors.textPrimary,
  fontWeight: FontWeight.w500,
  fontSize: 22.0,
  height: 1.3,
);

const TextStyle whiteLargeTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 20.0,
  height: 1.3,
);

TextStyle whiteSmallTextStyle = TextStyle(
  color: Colors.white.withValues(alpha: 0.7),
  fontSize: 15.0,
  height: 1.3,
);

const TextStyle whiteNormalTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 17.0,
  height: 1.3,
);

const TextStyle whiteBottonTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 18.0,
);

const TextStyle blackBottonTextStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 18.0,
);

const TextStyle greyNormalTextStyle = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 18.0,
  height: 1.3,
);

const TextStyle greySmallTextStyle = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 15.0,
  height: 1.3,
);

const TextStyle greySmallBoldTextStyle = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 15.0,
  fontWeight: FontWeight.w500,
);

const TextStyle primaryColorHeadingTextStyle = TextStyle(
  color: AppColors.primary,
  fontSize: 18.0,
  fontWeight: FontWeight.w500,
);

const TextStyle primaryColorSmallTextStyle = TextStyle(
  color: AppColors.primary,
  fontSize: 16.0,
);

const TextStyle primaryColorSmallBoldTextStyle = TextStyle(
  color: AppColors.primary,
  fontSize: 15.0,
  fontWeight: FontWeight.w500,
);

const TextStyle primaryColorLignThroughSmallBoldTextStyle = TextStyle(
  color: AppColors.primary,
  fontSize: 15.0,
  fontWeight: FontWeight.w500,
  decoration: TextDecoration.lineThrough,
);

const TextStyle inputTextStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 16.0,
);

const TextStyle infoTextStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 14.0,
);

TextStyle orderPlacedTextStyle = TextStyle(
  color: Colors.grey[400],
  fontSize: 18.0,
);

const TextStyle priceTextStyle = TextStyle(
  color: AppColors.primary,
  fontSize: 18.0,
);

const TextStyle blueSmallTextStyle = TextStyle(
  color: AppColors.info,
  fontSize: 15.0,
);

const TextStyle yellowExtraLargeTextStyle = TextStyle(
  color: AppColors.accent,
  fontWeight: FontWeight.w500,
  fontSize: 40.0,
  height: 1.3,
);
