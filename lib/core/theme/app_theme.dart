import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Global ThemeData configuration for Dentera based on DESIGN.md
abstract final class AppTheme {
  /// Default light ThemeData (LTR) for backward-compatibility with existing tests and call sites.
  static ThemeData get lightTheme => lightThemeForLocale();

  /// Default dark ThemeData (LTR) for backward-compatibility with existing tests and call sites.
  static ThemeData get darkTheme => darkThemeForLocale();

  /// Locale-aware light theme configuration.
  static ThemeData lightThemeForLocale([Locale? locale]) {
    final bool isArabic = locale?.languageCode == 'ar';
    final ColorScheme colorScheme = const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      inversePrimary: AppColors.inversePrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      surfaceTint: AppColors.surfaceTint,
    );

    final TextTheme baseTextTheme = isArabic
        ? GoogleFonts.cairoTextTheme()
        : GoogleFonts.hankenGroteskTextTheme();
    final TextTheme textTheme = baseTextTheme.copyWith(
      displayLarge: isArabic ? AppTextStyles.arabicH1 : AppTextStyles.h1,
      displayMedium: isArabic ? AppTextStyles.arabicH1Mobile : AppTextStyles.h1Mobile,
      displaySmall: isArabic ? AppTextStyles.arabicH2 : AppTextStyles.h2,
      headlineLarge: isArabic ? AppTextStyles.arabicH1 : AppTextStyles.h1,
      headlineMedium: isArabic ? AppTextStyles.arabicH1Mobile : AppTextStyles.h1Mobile,
      headlineSmall: isArabic ? AppTextStyles.arabicH2 : AppTextStyles.h2,
      titleLarge: isArabic ? AppTextStyles.arabicDisplayWordmark : AppTextStyles.displayWordmark,
      titleMedium: isArabic ? AppTextStyles.arabicH2 : AppTextStyles.h2,
      titleSmall: (isArabic ? AppTextStyles.arabicBodyMd : AppTextStyles.bodyMd).copyWith(fontWeight: FontWeight.w600),
      bodyLarge: (isArabic ? AppTextStyles.arabicBodyMd : AppTextStyles.bodyMd).copyWith(fontSize: 16),
      bodyMedium: isArabic ? AppTextStyles.arabicBodyMd : AppTextStyles.bodyMd,
      bodySmall: isArabic ? AppTextStyles.arabicCaption : AppTextStyles.caption,
      labelLarge: (isArabic ? AppTextStyles.arabicBodyMd : AppTextStyles.bodyMd).copyWith(fontWeight: FontWeight.w600),
      labelMedium: isArabic ? AppTextStyles.arabicCaption : AppTextStyles.caption,
      labelSmall: isArabic ? AppTextStyles.arabicLabelCaps : AppTextStyles.labelCaps,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      fontFamily: isArabic
          ? GoogleFonts.cairo().fontFamily
          : GoogleFonts.hankenGrotesk().fontFamily,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: (isArabic ? AppTextStyles.arabicH2 : AppTextStyles.h2).copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.onSurface,
          size: 24,
        ),
      ),

      // Card Theme (18px radius per DESIGN.md lines 147, 158)
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(
            color: AppColors.outlineVariant,
            width: 1,
          ),
        ),
      ),

      // Elevated Button Theme (Primary Action Button, 12px radius, 48px height)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.surfaceContainerHigh,
          disabledForegroundColor: AppColors.outline,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.02,
          ),
        ),
      ),

      // Outlined Button Theme (Secondary Button, 12px radius, 48px height, 1px border)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.outline,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(
            color: AppColors.primary,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.02,
          ),
        ),
      ),

      // Text Button Theme (12px radius)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.outline,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme (12px radius, white fill, 1px/2px border)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.outline),
        labelStyle: AppTextStyles.caption.copyWith(color: AppColors.onSurfaceVariant),
        floatingLabelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        helperStyle: AppTextStyles.caption,
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.outlineVariant,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.outlineVariant,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme (2D stroke outlines)
      iconTheme: const IconThemeData(
        color: AppColors.onSurfaceVariant,
        size: 24,
      ),
    );
  }

  /// Global dark ThemeData configuration for Dentera based on DESIGN.md
  static ThemeData darkThemeForLocale([Locale? locale]) {
    final ThemeData baseLight = lightThemeForLocale(locale);
    final ColorScheme colorScheme = const ColorScheme.dark(
      primary: AppColors.inversePrimary,
      onPrimary: AppColors.onPrimaryFixed,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      inversePrimary: AppColors.primary,
      secondary: AppColors.secondaryFixedDim,
      onSecondary: AppColors.onSecondaryFixed,
      secondaryContainer: AppColors.secondary,
      onSecondaryContainer: AppColors.secondaryContainer,
      tertiary: AppColors.tertiaryFixedDim,
      onTertiary: AppColors.onTertiaryFixed,
      tertiaryContainer: AppColors.tertiary,
      onTertiaryContainer: AppColors.tertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.inverseSurface,
      onSurface: AppColors.inverseOnSurface,
      onSurfaceVariant: AppColors.surfaceDim,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.surface,
      onInverseSurface: AppColors.onSurface,
      surfaceTint: AppColors.surfaceTint,
    );

    return baseLight.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.inverseSurface,
      appBarTheme: baseLight.appBarTheme.copyWith(
        backgroundColor: AppColors.inverseSurface,
        foregroundColor: AppColors.inverseOnSurface,
      ),
    );
  }
}

