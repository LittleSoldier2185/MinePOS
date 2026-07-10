import 'package:flutter/material.dart';

import 'app_settings_service.dart';

/// Drives the app's active [Locale] so a language change in Settings takes
/// effect immediately, without restarting the app.
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final instance = LocaleController._();

  Locale locale = const Locale('en');

  void setLanguage(AppLanguage language) {
    locale = Locale(language == AppLanguage.thai ? 'th' : 'en');
    notifyListeners();
  }
}
