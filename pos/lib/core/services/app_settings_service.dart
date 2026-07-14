import 'package:shared_preferences/shared_preferences.dart';

enum PrinterChoice { bluetooth, usb, skip }

enum AppLanguage { english, thai }

/// Thermal paper roll width. Names match the industry-standard nominal
/// sizes (a "58mm" roll is actually ~57mm of printable paper, "80mm" ~76mm).
enum ReceiptPaperSize { mm58, mm80 }

/// Small persisted local preferences (this device only — not synced to the
/// server). Distinct from [ShopSetupData], which only lives for the
/// duration of the onboarding wizard.
class AppSettingsService {
  AppSettingsService._();
  static final instance = AppSettingsService._();

  static const _kPrinterKey = 'settings.printerChoice';
  static const _kLanguageKey = 'settings.language';
  static const _kPrinterDeviceIdKey = 'settings.printerDeviceId';
  static const _kPrinterDeviceNameKey = 'settings.printerDeviceName';
  static const _kPaperSizeKey = 'settings.paperSize';
  static const _kMenuGridViewKey = 'settings.menuGridView';
  static const _kStaffGridViewKey = 'settings.staffGridView';

  Future<bool> getMenuGridView() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kMenuGridViewKey) ?? true;
  }

  Future<void> setMenuGridView(bool isGridView) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMenuGridViewKey, isGridView);
  }

  Future<bool> getStaffGridView() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kStaffGridViewKey) ?? false;
  }

  Future<void> setStaffGridView(bool isGridView) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kStaffGridViewKey, isGridView);
  }

  Future<ReceiptPaperSize> getPaperSize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPaperSizeKey);
    return ReceiptPaperSize.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => ReceiptPaperSize.mm80,
    );
  }

  Future<void> setPaperSize(ReceiptPaperSize size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPaperSizeKey, size.name);
  }

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

  /// The specific printer to use, identified by a stable key derived from
  /// its transport + address (see `printerDeviceKey` in printer_service.dart).
  /// Null means "no specific printer remembered — use whatever is found first".
  Future<String?> getSelectedPrinterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPrinterDeviceIdKey);
  }

  /// Human-readable name of the remembered printer, for display only.
  Future<String?> getSelectedPrinterName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPrinterDeviceNameKey);
  }

  Future<void> setSelectedPrinter({required String id, required String name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrinterDeviceIdKey, id);
    await prefs.setString(_kPrinterDeviceNameKey, name);
  }

  Future<void> clearSelectedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrinterDeviceIdKey);
    await prefs.remove(_kPrinterDeviceNameKey);
  }
}
