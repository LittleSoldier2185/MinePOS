import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/api_client.dart';
import '../../../core/services/server_client.dart';
import '../models/staff_member.dart';

/// Staff accounts are managed server-side only — there is no offline
/// fallback, since these are security-sensitive, owner-only operations.
class StaffService {
  StaffService._();
  static final instance = StaffService._();

  Future<List<StaffMember>> fetchAll() async {
    final res = await apiSend(() => http.get(
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
    String? name,
    String? email,
    String? phone,
    String? avatarBase64,
  }) async {
    final res = await apiSend(() => http.post(
          ServerClient.instance.uri('/users'),
          headers: ServerClient.instance.headers,
          body: jsonEncode({
            'username': username.trim(),
            'password': password,
            'role': role,
            'name': name,
            'email': email,
            'phone': phone,
            'avatarBase64': avatarBase64,
          }),
        ));
    return StaffMember.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<StaffMember> setActive(int id, bool active) async {
    final res = await apiSend(() => http.patch(
          ServerClient.instance.uri('/users/$id'),
          headers: ServerClient.instance.headers,
          body: jsonEncode({'active': active}),
        ));
    return StaffMember.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// [password] omitted or empty leaves the current password unchanged.
  /// [name]/[email]/[phone]/[avatarBase64] are always sent together as a
  /// full profile replace (same shape as the menu item edit form) — pass an
  /// empty string/null to clear a field, not just to leave it unchanged.
  /// [username] renames the account and requires [confirmPassword] — the
  /// *acting* owner's own password, not the target account's — pass both
  /// only when the username actually changed.
  Future<StaffMember> update(
    int id, {
    required String role,
    String? password,
    String? name,
    String? email,
    String? phone,
    String? avatarBase64,
    String? username,
    String? confirmPassword,
  }) async {
    final res = await apiSend(() => http.patch(
          ServerClient.instance.uri('/users/$id'),
          headers: ServerClient.instance.headers,
          body: jsonEncode({
            'role': role,
            if (password != null && password.isNotEmpty) 'password': password,
            'name': name,
            'email': email,
            'phone': phone,
            'avatarBase64': avatarBase64,
            if (username != null) 'username': username,
            if (confirmPassword != null) 'confirmPassword': confirmPassword,
          }),
        ));
    return StaffMember.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> forceLogout(int id) => apiSend(() => http.post(
        ServerClient.instance.uri('/users/$id/logout'),
        headers: ServerClient.instance.headers,
      ));

  Future<void> delete(int id) => apiSend(() => http.delete(
        ServerClient.instance.uri('/users/$id'),
        headers: ServerClient.instance.headers,
      ));

}
