import 'package:flutter/foundation.dart';

import 'app_settings_service.dart';

/// Singleton that stores the connected server address and auth token.
/// Set [baseUrl] when a connection test passes; set [token] after login.
/// Call [clear] on logout.
///
/// Extends [ChangeNotifier] solely so [updateOwnProfile] can tell an
/// already-mounted screen (the sidebar/app-bar user card) to refresh
/// immediately — every other field is still just set directly by callers
/// (login, auto-login) since those always happen right before a fresh
/// widget tree is built anyway and don't need a live-update signal.
class ServerClient extends ChangeNotifier {
  ServerClient._();
  static final instance = ServerClient._();

  String? baseUrl; // e.g. "192.168.1.10:8080"
  String? token;
  String? role; // "owner" | "manager" | "worker"
  String? username;
  int? userId;

  /// The signed-in user's display name/avatar, shown in the sidebar/app bar
  /// user card — null falls back to [username]/an initial-letter avatar.
  /// Set at login and refreshed whenever the user edits their own profile in
  /// Staff Management (see `staff_management_screen.dart`).
  String? name;
  String? avatarBase64;

  /// Updates the signed-in user's own display name/avatar and notifies
  /// listeners, so the sidebar/app-bar user card reflects a self-edit made
  /// in Staff Management right away instead of waiting for the next login.
  void updateOwnProfile({String? name, String? avatarBase64}) {
    this.name = name;
    this.avatarBase64 = avatarBase64;
    notifyListeners();
  }

  /// This station's name, set at login (e.g. "Register 1") — lets two
  /// devices signed in as the same account show up as distinct stations in
  /// presence tracking, and lets the customer display pick which register's
  /// cart to mirror. Null on a device that never logged in (e.g. a
  /// customer-display-only connection).
  String? deviceName;

  bool get isConnected => baseUrl != null;
  bool get isOwner => role == 'owner';

  /// Owner and manager can manage the menu and view reports; a plain
  /// employee ("worker") can only take orders and use the kitchen board.
  bool get canManageShop => role == 'owner' || role == 'manager';

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri uri(String path) => Uri.parse('http://$baseUrl$path');

  /// Browsers can't set custom headers on a WebSocket handshake, so the
  /// token travels as a query param here instead of the usual header.
  /// [query] adds further params (e.g. the customer-display station name).
  Uri wsUri(String path, {Map<String, String>? query}) {
    final params = <String, String>{...?query};
    if (token != null) params['token'] = token!;
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return Uri.parse('ws://$baseUrl$path${qs.isEmpty ? '' : '?$qs'}');
  }

  /// Every call site of this is some form of "sign out" (logout, disconnect,
  /// remove shop) — so it also drops any remembered "stay signed in" session
  /// and disables auto-login here, once, rather than relying on each call site
  /// to remember to do it. (An idle-timeout token rejection is *not* a sign-out
  /// and goes through `AppSettingsService.clearSession()` alone instead.)
  void clear() {
    baseUrl = null;
    token = null;
    role = null;
    username = null;
    userId = null;
    name = null;
    avatarBase64 = null;
    deviceName = null;
    AppSettingsService.instance.clearSession();
    AppSettingsService.instance.setAutoLogin(false);
  }
}
