import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Master typography rules extracted directly from `DESIGN.md`.
abstract final class AppTextStyles {
  /// Display Wordmark: Plus Jakarta Sans, 20px, w600, line-height 24px, letter-spacing 0.05em
  static TextStyle get displayWordmark => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 24 / 20,
        letterSpacing: 20 * 0.05,
      );

  /// H1: Plus Jakarta Sans, 24px, w600, line-height 32px
  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
      );

  /// H1 Mobile: Plus Jakarta Sans, 20px, w600, line-height 28px
  static TextStyle get h1Mobile => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
      );

  /// H2: Plus Jakarta Sans, 18px, w500, line-height 26px
  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 26 / 18,
      );

  /// Body MD: Hanken Grotesk, 14px, w400, line-height 22px
  static TextStyle get bodyMd => GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 22 / 14,
      );

  /// Caption: Hanken Grotesk, 12px, w500, line-height 16px
  static TextStyle get caption => GoogleFonts.hankenGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
      );

  /// Label Caps: Hanken Grotesk, 11px, w700, line-height 14px, letter-spacing 0.02em
  static TextStyle get labelCaps => GoogleFonts.hankenGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 14 / 11,
        letterSpacing: 11 * 0.02,
      );

  /// Returns the appropriate font family for the given locale.
  static String? fontFamilyForLocale([Locale? locale]) {
    if (locale?.languageCode == 'ar') {
      return GoogleFonts.cairo().fontFamily;
    }
    return GoogleFonts.hankenGrotesk().fontFamily;
  }

  /// Arabic typography using GoogleFonts.cairo
  static TextStyle get arabicDisplayWordmark => GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 24 / 20,
        letterSpacing: 20 * 0.05,
      );

  static TextStyle get arabicH1 => GoogleFonts.cairo(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
      );

  static TextStyle get arabicH1Mobile => GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
      );

  static TextStyle get arabicH2 => GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 26 / 18,
      );

  static TextStyle get arabicBodyMd => GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 22 / 14,
      );

  static TextStyle get arabicCaption => GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
      );

  static TextStyle get arabicLabelCaps => GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 14 / 11,
        letterSpacing: 11 * 0.02,
      );
}

/// Clinical Linearity Dark typography tokens.
abstract final class AppDarkTextStyles {
  static TextStyle get displayWordmark =>
      AppTextStyles.displayWordmark.copyWith(color: AppDarkColors.textPrimary);
  static TextStyle get h1 =>
      AppTextStyles.h1.copyWith(color: AppDarkColors.textPrimary);
  static TextStyle get h1Mobile =>
      AppTextStyles.h1Mobile.copyWith(color: AppDarkColors.textPrimary);
  static TextStyle get h2 =>
      AppTextStyles.h2.copyWith(color: AppDarkColors.textPrimary);
  static TextStyle get bodyMd =>
      AppTextStyles.bodyMd.copyWith(color: AppDarkColors.textPrimary);
  static TextStyle get caption =>
      AppTextStyles.caption.copyWith(color: AppDarkColors.textMuted);
  static TextStyle get labelCaps =>
      AppTextStyles.labelCaps.copyWith(color: AppDarkColors.textMuted);
}
