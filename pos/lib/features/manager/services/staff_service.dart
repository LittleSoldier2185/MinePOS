import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/server_client.dart';
import '../models/staff_member.dart';

class StaffServiceException implements Exception {
  StaffServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Staff accounts are managed server-side only — there is no offline
/// fallback, since these are security-sensitive, owner-only operations.
class StaffService {
  StaffService._();
  static final instance = StaffService._();

  Future<List<StaffMember>> fetchAll() async {
    final res = await _send(() => http.get(
          ServerClient.instance.uri('/users'),
          headers: ServerClient.instance.headers,
        ));
    final list = jsonDecode(res.body) as List;
    return list
        .map((j) => StaffMember.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<StaffMember> create({
    required String username,
    required String password,
    required String role,
  }) async {
    final res = await _send(() => http.post(
          ServerClient.instance.uri('/users'),
          headers: ServerClient.instance.headers,
          body: jsonEncode({
            'username': username.trim(),
            'password': password,
            'role': role,
          }),
        ));
    return StaffMember.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<StaffMember> setActive(String username, bool active) async {
    final res = await _send(() => http.patch(
          ServerClient.instance.uri('/users/$username'),
          headers: ServerClient.instance.headers,
          body: jsonEncode({'active': active}),
        ));
    return StaffMember.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// [password] omitted or empty leaves the current password unchanged.
  Future<StaffMember> update(String username, {required String role, String? password}) async {
    final res = await _send(() => http.patch(
          ServerClient.instance.uri('/users/$username'),
          headers: ServerClient.instance.headers,
          body: jsonEncode({
            'role': role,
            if (password != null && password.isNotEmpty) 'password': password,
          }),
        ));
    return StaffMember.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> forceLogout(String username) => _send(() => http.post(
        ServerClient.instance.uri('/users/$username/logout'),
        headers: ServerClient.instance.headers,
      ));

  Future<void> delete(String username) => _send(() => http.delete(
        ServerClient.instance.uri('/users/$username'),
        headers: ServerClient.instance.headers,
      ));

  Future<http.Response> _send(
      Future<http.Response> Function() request) async {
    final client = ServerClient.instance;
    if (!client.isConnected) {
      throw StaffServiceException('Not connected to a server');
    }
    late final http.Response res;
    try {
      res = await request().timeout(const Duration(seconds: 10));
    } catch (_) {
      throw StaffServiceException('Could not reach the server');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return res;
    throw StaffServiceException(_errorMessage(res));
  }

  String _errorMessage(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['error'] as String? ?? 'Request failed (${res.statusCode})';
    } catch (_) {
      return 'Request failed (${res.statusCode})';
    }
  }
}
