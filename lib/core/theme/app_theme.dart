import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Global ThemeData configuration for Dentera based on DESIGN.md
abstract final class AppTheme {
  static ThemeData get lightTheme {
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

    final TextTheme baseTextTheme = GoogleFonts.hankenGroteskTextTheme();
    final TextTheme textTheme = baseTextTheme.copyWith(
      displayLarge: AppTextStyles.h1,
      displayMedium: AppTextStyles.h1Mobile,
      displaySmall: AppTextStyles.h2,
      headlineLarge: AppTextStyles.h1,
      headlineMedium: AppTextStyles.h1Mobile,
      headlineSmall: AppTextStyles.h2,
      titleLarge: AppTextStyles.displayWordmark,
      titleMedium: AppTextStyles.h2,
      titleSmall: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: AppTextStyles.bodyMd.copyWith(fontSize: 16),
      bodyMedium: AppTextStyles.bodyMd,
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
      labelMedium: AppTextStyles.caption,
      labelSmall: AppTextStyles.labelCaps,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      fontFamily: GoogleFonts.hankenGrotesk().fontFamily,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.h2.copyWith(
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
}
