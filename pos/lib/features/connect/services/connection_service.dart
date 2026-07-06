import 'package:http/http.dart' as http;

class ConnectionService {
  /// Returns true if [address] responds to the MinePOS health endpoint.
  /// Sets no global state — the caller (ConnectScreen) stores the address.
  Future<bool> testConnection(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return false;

    try {
      final url = Uri.parse('http://$trimmed/health');
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
