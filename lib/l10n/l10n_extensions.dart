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
