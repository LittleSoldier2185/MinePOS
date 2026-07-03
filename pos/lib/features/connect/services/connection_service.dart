/// Stubbed connection check — no MinePOS host server exists yet.
/// Swap the body of [testConnection] for a real HTTP health-check call
/// (e.g. `GET http://$address/health`) once the Dart Shelf host exists.
class ConnectionService {
  Future<bool> testConnection(String address) async {
    await Future.delayed(const Duration(milliseconds: 900));

    final trimmed = address.trim();
    if (trimmed.isEmpty) return false;

    // A bare minimum shape check so obviously-invalid input fails visibly.
    final hostPortPattern = RegExp(r'^[\w.\-]+(:\d{1,5})?$');
    return hostPortPattern.hasMatch(trimmed);
  }
}
