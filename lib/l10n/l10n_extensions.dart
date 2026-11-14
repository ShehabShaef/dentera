import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Extension on [BuildContext] providing convenient, non-null access to [AppLocalizations].
extension AppLocalizationsX on BuildContext {
  /// Returns the nearest [AppLocalizations] instance from the widget tree,
  /// or falls back to default translations if no delegate is present (e.g. in tests).
  AppLocalizations get l10n {
    final localized = AppLocalizations.of(this);
    if (localized != null) {
      return localized;
    }
    final locale = Localizations.maybeLocaleOf(this) ?? const Locale('en');
    return lookupAppLocalizations(
      locale.languageCode == 'ar' ? const Locale('ar') : const Locale('en'),
    );
  }
}

/// Extension providing centralized localization helpers for enum values,
/// status chips, and academic years.
extension AppLocalizationsFormattingX on AppLocalizations {
  /// Localizes standard clinical status strings (case or appointment).
  String localizeStatus(String? status) {
    if (status == null || status.trim().isEmpty) return '';
    final normalized = status.trim().toLowerCase().replaceAll('_', ' ');

    switch (normalized) {
      case 'scheduled':
        return statusScheduled;
      case 'confirmed':
        return statusConfirmed;
      case 'in progress':
        return statusInProgress;
      case 'completed':
        return statusCompleted;
      case 'cancelled':
      case 'canceled':
        return statusCancelled;
      case 'evaluated':
        return statusEvaluated;
      case 'pending':
        return statusPending;
      default:
        return status;
    }
  }

  /// Localizes academic year level strings according to active locale.
  String localizeAcademicYear(String? year) {
    if (year == null || year.trim().isEmpty) return '';
    final isAr = localeName.startsWith('ar');
    if (!isAr) return year;

    final trimmed = year.trim().toLowerCase();
    if (trimmed.contains('1st') || trimmed.contains('first')) return 'السنة الأولى';
    if (trimmed.contains('2nd') || trimmed.contains('second')) return 'السنة الثانية';
    if (trimmed.contains('3rd') || trimmed.contains('third')) return 'السنة الثالثة';
    if (trimmed.contains('4th') || trimmed.contains('fourth')) return 'السنة الرابعة';
    if (trimmed.contains('5th') || trimmed.contains('fifth')) return 'السنة الخامسة';
    if (trimmed.contains('intern')) return 'سنة الامتياز';
    if (trimmed.contains('postgraduate') || trimmed.contains('master')) return 'الدراسات العليا';

    return year;
  }
}
