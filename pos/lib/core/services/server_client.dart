/// Singleton that stores the connected server address and auth token.
/// Set [baseUrl] when a connection test passes; set [token] after login.
/// Call [clear] on logout.
class ServerClient {
  ServerClient._();
  static final instance = ServerClient._();

  String? baseUrl; // e.g. "192.168.1.10:8080"
  String? token;
  String? role; // "owner" | "manager" | "worker"
  String? username;

  bool get isConnected => baseUrl != null;
  bool get isOwner => role == 'owner';

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri uri(String path) => Uri.parse('http://$baseUrl$path');

  /// Browsers can't set custom headers on a WebSocket handshake, so the
  /// token travels as a query param here instead of the usual header.
  Uri wsUri(String path) =>
      Uri.parse('ws://$baseUrl$path${token != null ? '?token=$token' : ''}');

  void clear() {
    baseUrl = null;
    token = null;
    role = null;
    username = null;
  }
}
