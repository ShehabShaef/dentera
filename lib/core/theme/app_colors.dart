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

/// Clinical Linearity Dark palette extracted directly from `prompt/ui/00 dark_theme/DESIGN.md`.
abstract final class AppDarkColors {
  // Surface tokens
  static const Color surface = Color(0xFF0C141F);
  static const Color surfaceDim = Color(0xFF0C141F);
  static const Color surfaceBright = Color(0xFF323A46);
  static const Color surfaceContainerLowest = Color(0xFF070F19);
  static const Color surfaceContainerLow = Color(0xFF141C27);
  static const Color surfaceContainer = Color(0xFF141F2E);
  static const Color surfaceContainerHigh = Color(0xFF232A36);
  static const Color surfaceContainerHighest = Color(0xFF2D3541);
  static const Color surfaceContainerElevated = Color(0xFF1A293B);
  static const Color surfaceVariant = Color(0xFF2D3541);
  static const Color surfaceBase = Color(0xFF0D1520);
  static const Color surfaceBorder = Color(0xFF23354D);
  static const Color elevatedBorder = Color(0xFF2B3E57);
  static const Color onSurface = Color(0xFFDBE3F3);
  static const Color onSurfaceVariant = Color(0xFFBACAC4);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF728299);
  static const Color textPlaceholder = Color(0xFF64748B);
  static const Color inverseSurface = Color(0xFFDBE3F3);
  static const Color inverseOnSurface = Color(0xFF29313D);
  static const Color surfaceTint = Color(0xFF2ADEC0);

  // Background tokens
  static const Color background = Color(0xFF0C141F);
  static const Color onBackground = Color(0xFFDBE3F3);

  // Outline tokens
  static const Color outline = Color(0xFF85948F);
  static const Color outlineVariant = Color(0xFF23354D);
  static const Color borderSubtle = Color(0xFF23354D);
  static const Color borderMuted = Color(0xFF23354D);
  static const Color dragHandle = Color(0xFF2B3E57);
  static const Color inputFill = Color(0xFF0E1724);
  static const Color canvasBackground = Color(0xFF0C141F);
  static const Color progressTrack = Color(0xFF2D3541);

  // Primary palette (Luminous Teal)
  static const Color primary = Color(0xFF46EFCF);
  static const Color primaryTeal = primary;
  static const Color tealAccent = primary;
  static const Color onPrimary = Color(0xFF00382E);
  static const Color onTeal = onPrimary;
  static const Color primaryContainer = Color(0xFF00D2B4);
  static const Color onPrimaryContainer = Color(0xFF005547);
  static const Color inversePrimary = Color(0xFF006B5B);
  static const Color primaryFixed = Color(0xFF57FBDB);
  static const Color primaryFixedDim = Color(0xFF2ADEC0);
  static const Color onPrimaryFixed = Color(0xFF00201A);
  static const Color onPrimaryFixedVariant = Color(0xFF005144);

  // Secondary palette
  static const Color secondary = Color(0xFF48F9DD);
  static const Color onSecondary = Color(0xFF003730);
  static const Color secondaryContainer = Color(0xFF00DCC1);
  static const Color onSecondaryContainer = Color(0xFF005B4F);
  static const Color secondaryFixed = Color(0xFF4CFCE0);
  static const Color secondaryFixedDim = Color(0xFF0EDFC4);
  static const Color onSecondaryFixed = Color(0xFF00201B);
  static const Color onSecondaryFixedVariant = Color(0xFF005046);

  // Tertiary palette
  static const Color tertiary = Color(0xFFBDD9FF);
  static const Color onTertiary = Color(0xFF00325A);
  static const Color tertiaryContainer = Color(0xFF8EBEFA);
  static const Color onTertiaryContainer = Color(0xFF0E4C82);
  static const Color tertiaryFixed = Color(0xFFD2E4FF);
  static const Color tertiaryFixedDim = Color(0xFFA0C9FF);
  static const Color onTertiaryFixed = Color(0xFF001C37);
  static const Color onTertiaryFixedVariant = Color(0xFF05497E);

  // Semantic & Error palette
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);
  static const Color statusError = Color(0xFFFF5252);
  static const Color statusWarning = Color(0xFFF59E0B);

  // Dark Brand Gradient
  static const LinearGradient brandGradient = LinearGradient(
    colors: <Color>[
      Color(0xFF003730),
      Color(0xFF002B3D),
      Color(0xFF0C141F),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Dark Ambient Card & Container Shadow
  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x73000000), // rgba(0, 0, 0, 0.45)
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];
}
