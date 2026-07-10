import 'package:shared_preferences/shared_preferences.dart';

enum PrinterChoice { bluetooth, usb, skip }

enum AppLanguage { english, thai }

/// Small persisted local preferences (this device only — not synced to the
/// server). Distinct from [ShopSetupData], which only lives for the
/// duration of the onboarding wizard.
class AppSettingsService {
  AppSettingsService._();
  static final instance = AppSettingsService._();

  static const _kPrinterKey = 'settings.printerChoice';
  static const _kLanguageKey = 'settings.language';

  Future<PrinterChoice> getPrinterChoice() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrinterKey);
    return PrinterChoice.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => PrinterChoice.skip,
    );
  }

  Future<void> setPrinterChoice(PrinterChoice choice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrinterKey, choice.name);
  }

  Future<AppLanguage> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLanguageKey);
    return AppLanguage.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => AppLanguage.english,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, language.name);
  }
}
