import 'dart:convert';

import 'package:http/http.dart' as http;

class ServerStatus {
  const ServerStatus({required this.reachable, required this.hasShop});
  final bool reachable;
  final bool hasShop;
}

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

  /// Like [testConnection], but also reports whether the server at
  /// [address] already has a shop set up — used by the Create Shop wizard
  /// to block early instead of only failing at the final `POST /setup`.
  Future<ServerStatus> checkStatus(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return const ServerStatus(reachable: false, hasShop: false);

    try {
      final url = Uri.parse('http://$trimmed/health');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        return const ServerStatus(reachable: false, hasShop: false);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ServerStatus(reachable: true, hasShop: body['hasShop'] as bool? ?? false);
    } catch (_) {
      return const ServerStatus(reachable: false, hasShop: false);
    }
  }
}
