import 'package:flutter/material.dart';

/// Master color palette extracted directly from `DESIGN.md` (Clinical Linearity).
abstract final class AppColors {
  // Surface tokens
  static const Color surface = Color(0xFFF7FAFC);
  static const Color surfaceDim = Color(0xFFD7DADC);
  static const Color surfaceBright = Color(0xFFF7FAFC);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F4F6);
  static const Color surfaceContainer = Color(0xFFEBEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE5E9EB);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);
  static const Color surfaceVariant = Color(0xFFE0E3E5);
  static const Color onSurface = Color(0xFF181C1E);
  static const Color onSurfaceVariant = Color(0xFF42474F);
  /// Standard alias for secondary / muted body text across Clinical Linearity components.
  static const Color textSecondary = onSurfaceVariant;
  static const Color inverseSurface = Color(0xFF2D3133);
  static const Color inverseOnSurface = Color(0xFFEEF1F3);
  static const Color surfaceTint = Color(0xFF2C6197);

  // Background tokens
  static const Color background = Color(0xFFF7FAFC);
  static const Color onBackground = Color(0xFF181C1E);

  // Outline tokens
  static const Color outline = Color(0xFF727780);
  static const Color outlineVariant = Color(0xFFC2C7D1);

  // Primary palette
  static const Color primary = Color(0xFF003E6F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1E568C);
  static const Color onPrimaryContainer = Color(0xFFA4CBFF);
  static const Color inversePrimary = Color(0xFFA0C9FF);
  static const Color primaryFixed = Color(0xFFD2E4FF);
  static const Color primaryFixedDim = Color(0xFFA0C9FF);
  static const Color onPrimaryFixed = Color(0xFF001C37);
  static const Color onPrimaryFixedVariant = Color(0xFF05497E);

  // Secondary palette
  static const Color secondary = Color(0xFF006A64);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF81F6EB);
  static const Color onSecondaryContainer = Color(0xFF00716A);
  static const Color secondaryFixed = Color(0xFF81F6EB);
  static const Color secondaryFixedDim = Color(0xFF62D9CF);
  static const Color onSecondaryFixed = Color(0xFF00201E);
  static const Color onSecondaryFixedVariant = Color(0xFF00504B);

  // Tertiary palette
  static const Color tertiary = Color(0xFF2E3F50);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF455668);
  static const Color onTertiaryContainer = Color(0xFFB9CBE0);
  static const Color tertiaryFixed = Color(0xFFD2E4FA);
  static const Color tertiaryFixedDim = Color(0xFFB6C8DE);
  static const Color onTertiaryFixed = Color(0xFF0A1D2D);
  static const Color onTertiaryFixedVariant = Color(0xFF37485A);

  // Semantic & Error palette
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Brand Gradient
  static const LinearGradient brandGradient = LinearGradient(
    colors: <Color>[primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Ambient Card & Container Shadow
  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A2A3B4C), // 0 4px 24px rgba(42, 59, 76, 0.04)
      blurRadius: 24,
      offset: Offset(0, 4),
    ),
  ];
}
