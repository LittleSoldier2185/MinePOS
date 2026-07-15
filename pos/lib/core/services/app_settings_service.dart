import 'package:shared_preferences/shared_preferences.dart';

enum PrinterChoice { bluetooth, usb, skip }

enum AppLanguage { english, thai }

/// A remembered "stay signed in" session — everything needed to silently
/// restore it on next launch without re-prompting for a server address or
/// credentials. `purpose` is a [DevicePurpose] name (only `staffHub` or
/// `kitchenOnly` — a customer display never logs in, so is never remembered).
typedef RememberedSession = ({String baseUrl, String token, String deviceName, String purpose});

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
  static const _kLastServerAddressKey = 'settings.lastServerAddress';
  static const _kDeviceNameKey = 'settings.deviceName';
  static const _kSessionBaseUrlKey = 'session.baseUrl';
  static const _kSessionTokenKey = 'session.token';
  static const _kSessionDeviceNameKey = 'session.deviceName';
  static const _kSessionPurposeKey = 'session.purpose';

  Future<String?> getLastServerAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastServerAddressKey);
  }

  Future<void> setLastServerAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastServerAddressKey, address);
  }

  /// This station's name (e.g. "Register 1") — a property of the physical
  /// till, not the account, so it's remembered per-installation and just
  /// prefilled (still editable) on the login form rather than retyped every
  /// sign-in.
  Future<String?> getDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDeviceNameKey);
  }

  Future<void> setDeviceName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDeviceNameKey, name);
  }

  /// Persists a "remember me" session — the auth token itself, not the
  /// password. Cleared by [clearSession] on explicit sign-out/disconnect,
  /// but *not* by simply closing the app, so the next launch can silently
  /// resume it (until the token itself expires or is revoked).
  Future<void> saveSession({
    required String baseUrl,
    required String token,
    required String deviceName,
    required String purpose,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionBaseUrlKey, baseUrl);
    await prefs.setString(_kSessionTokenKey, token);
    await prefs.setString(_kSessionDeviceNameKey, deviceName);
    await prefs.setString(_kSessionPurposeKey, purpose);
  }

  /// Null if nothing was remembered (or a previous session was only
  /// partially written, e.g. the app was killed mid-save).
  Future<RememberedSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString(_kSessionBaseUrlKey);
    final token = prefs.getString(_kSessionTokenKey);
    final deviceName = prefs.getString(_kSessionDeviceNameKey);
    final purpose = prefs.getString(_kSessionPurposeKey);
    if (baseUrl == null || token == null || deviceName == null || purpose == null) {
      return null;
    }
    return (baseUrl: baseUrl, token: token, deviceName: deviceName, purpose: purpose);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionBaseUrlKey);
    await prefs.remove(_kSessionTokenKey);
    await prefs.remove(_kSessionDeviceNameKey);
    await prefs.remove(_kSessionPurposeKey);
  }

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
