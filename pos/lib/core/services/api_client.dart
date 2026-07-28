import 'dart:convert';

import 'package:http/http.dart' as http;

import 'server_client.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Runs [request] against the connected server: throws [ApiException] if
/// there's no connection, the request can't reach the server, or the
/// response isn't 2xx (using the server's own `error` field when present).
/// Shared by every manager-feature service (ads, promotions, staff, shop,
/// reports) so each doesn't hand-roll the same connectivity/timeout/
/// error-message plumbing.
Future<http.Response> apiSend(
  Future<http.Response> Function() request, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  if (!ServerClient.instance.isConnected) {
    throw ApiException('Not connected to a server');
  }
  late final http.Response res;
  try {
    res = await request().timeout(timeout);
  } catch (_) {
    throw ApiException('Could not reach the server');
  }
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw ApiException(_errorMessage(res));
  }
  return res;
}

String _errorMessage(http.Response res) {
  try {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['error'] as String? ?? 'Request failed (${res.statusCode})';
  } catch (_) {
    return 'Request failed (${res.statusCode})';
  }
}
