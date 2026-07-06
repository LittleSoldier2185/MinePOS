/// Singleton that stores the connected server address and auth token.
/// Set [baseUrl] when a connection test passes; set [token] after login.
/// Call [clear] on logout.
class ServerClient {
  ServerClient._();
  static final instance = ServerClient._();

  String? baseUrl; // e.g. "192.168.1.10:8080"
  String? token;

  bool get isConnected => baseUrl != null;

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri uri(String path) => Uri.parse('http://$baseUrl$path');

  void clear() {
    baseUrl = null;
    token = null;
  }
}
