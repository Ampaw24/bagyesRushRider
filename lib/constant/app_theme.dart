import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';

/// GoPady App Theme
///
/// Primary: Brand green (#087A4B) — white text on it is 5.39:1
/// Secondary: Forest (#11231B) — splash, hero panels, snackbars
/// Accent: Golden yellow (#FFC928) — fills and large text on dark only
abstract final class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF087A4B);
  static const Color primaryLight = Color(0xFF0D9E62); // fills/icons only
  static const Color primaryDark = Color(0xFF065936);
  static const Color onPrimary = Colors.white;

  // Secondary palette — forest
  static const Color secondary = Color(0xFF11231B);
  static const Color secondaryLight = Color(0xFF233E32);
  static const Color secondaryDark = Color(0xFF0A1611);
  static const Color onSecondary = Colors.white;

  // Accent — golden yellow. A fill, never text on light surfaces.
  static const Color accent = Color(0xFFFFC928);
  static const Color accentLight = Color(0xFFFFD555);
  static const Color accentDark = Color(0xFFE5B017); // pressed
  static const Color accentInk = Color(0xFF855B00); // yellow-family text
  static const Color onAccent = Color(0xFF0A1611);

  // Brand moments (splash, onboarding, hero panels)
  static const Color forest = Color(0xFF0A1611);
  static const Color forestRaised = Color(0xFF11231B);
  static const Color forestHigh = Color(0xFF1A3328);
  static const Color onDark = Color(0xFFF4F9F5);
  static const Color onDarkMuted = Color(0xB8F4F9F5);
  static const Color onDarkSubtle = Color(0x8CF4F9F5);
  static const Color glow = Color(0xFF3DDC97); // green text/icons on forest

  // Surfaces
  static const Color scaffold = Colors.white;
  static const Color surface = Color(0xFFF4F9F5); // mint section background
  static const Color surfaceVariant = Color(0xFFEBF3EE);
  static const Color card = Colors.white;
  static const Color cream = Color(0xFFF9FCFA); // decorative backdrops

  // Text
  static const Color textPrimary = Color(0xFF11231B);
  static const Color textSecondary = Color(0xFF4B5E54);
  static const Color textHint = Color(0xFF586D62);

  // Borders & dividers
  static const Color border = Color(0xFFE1EBE4);
  static const Color divider = Color(0xFFEAF0EC);
  static const Color fieldBorder = Color(0xFF7B9185); // input outlines

  // Feedback
  static const Color success = Color(0xFF087A4B);
  static const Color error = Color(0xFFC53030);
  static const Color warning = Color(0xFFE59500); // fill only
  static const Color info = Color(0xFF2563EB);

  // "Awaiting payment" — read as text on light tints, so it uses accentInk.
  static const Color paymentPending = accentInk;

  // Shimmer / skeleton
  static const Color shimmerBase = Color(0xFFE1EBE4);
  static const Color shimmerHighlight = Color(0xFFF4F9F5);
}

abstract final class AppTheme {
  static const double _buttonMinHeight = 52;

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.surfaceVariant,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.surfaceVariant,
    onSecondaryContainer: AppColors.secondary,
    tertiary: AppColors.accentInk,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.accent,
    onTertiaryContainer: AppColors.onAccent,
    error: AppColors.error,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.fieldBorder,
    outlineVariant: AppColors.border,
    surfaceTint: Colors.transparent,
  );

  static const TextStyle _label = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const StadiumBorder _pill = StadiumBorder();

  /// Pill button on a forest surface: yellow fill, dark label.
  static final ButtonStyle onDarkButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: AppColors.onAccent,
    minimumSize: const Size(0, _buttonMinHeight),
    elevation: 0,
    shape: _pill,
    textStyle: _label,
  );

  /// Pill button on a forest surface: white 10% fill, white 20% border.
  static final ButtonStyle glassButton = OutlinedButton.styleFrom(
    backgroundColor: Colors.white.withValues(alpha: 0.10),
    foregroundColor: AppColors.onDark,
    minimumSize: const Size(0, _buttonMinHeight),
    shape: _pill,
    side: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
    textStyle: _label,
  );

  static OutlineInputBorder _inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: color, width: width),
      );

  static ThemeData get light {
    const colorScheme = _colorScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppFonts.body,
      scaffoldBackgroundColor: AppColors.scaffold,
      textTheme: _textTheme,

      // AppBar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        backgroundColor: AppColors.scaffold,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.display,
          color: AppColors.textPrimary,
          fontSize: 19.0,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textHint,
          elevation: 0,
          minimumSize: const Size(0, _buttonMinHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: _pill,
          textStyle: _label,
        ),
      ),

      // Filled buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(0, _buttonMinHeight),
          shape: _pill,
          textStyle: _label,
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, _buttonMinHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: _pill,
          side: const BorderSide(color: AppColors.primary),
          textStyle: _label,
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: _pill,
          textStyle: _label.copyWith(fontSize: 15),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _inputBorder(AppColors.fieldBorder),
        enabledBorder: _inputBorder(AppColors.fieldBorder),
        focusedBorder: _inputBorder(AppColors.primary, 2),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, 2),
        hintStyle: const TextStyle(
          fontFamily: AppFonts.body,
          color: AppColors.textHint,
          fontSize: 15,
        ),
        labelStyle: const TextStyle(
          fontFamily: AppFonts.body,
          color: AppColors.textSecondary,
          fontSize: 15,
        ),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.scaffold,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12,
        ),
      ),

      // TabBar
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary,
        labelStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 15,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        secondarySelectedColor: AppColors.primary.withValues(alpha: 0.12),
        labelStyle: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // Time picker — explicit white background so the dial stays crisp
      // against the mint `AppColors.surface`.
      timePickerTheme: TimePickerThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
      ),

      // Bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.scaffold,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),

      // Floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
        shape: CircleBorder(),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.forestRaised,
        contentTextStyle: const TextStyle(
          fontFamily: AppFonts.body,
          color: AppColors.onDark,
          fontSize: 14,
        ),
        actionTextColor: AppColors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.snackbar),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Text selection
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: Color(0x40087A4B),
        selectionHandleColor: AppColors.primary,
      ),

      // Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }

  /// Outfit for display/title roles, Inter for body and labels. Sizes stay
  /// at Material's defaults so OS text scaling keeps working unclamped.
  static final TextTheme _textTheme = () {
    const display = TextStyle(
      fontFamily: AppFonts.display,
      color: AppColors.textPrimary,
    );
    const body = TextStyle(
      fontFamily: AppFonts.body,
      color: AppColors.textPrimary,
    );
    return TextTheme(
      displayLarge: display.copyWith(fontWeight: FontWeight.w800),
      displayMedium: display.copyWith(fontWeight: FontWeight.w800),
      displaySmall: display.copyWith(fontWeight: FontWeight.w800),
      headlineLarge: display.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: display.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: display.copyWith(fontWeight: FontWeight.w700),
      titleLarge: display.copyWith(fontWeight: FontWeight.w600),
      titleMedium: body.copyWith(fontWeight: FontWeight.w600),
      titleSmall: body.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: body.copyWith(height: 1.5),
      bodyMedium: body.copyWith(height: 1.5),
      bodySmall: body.copyWith(color: AppColors.textSecondary),
      labelLarge: body.copyWith(fontWeight: FontWeight.w600),
      labelMedium: body.copyWith(fontWeight: FontWeight.w500),
      labelSmall: body.copyWith(color: AppColors.textHint),
    );
  }();
}
