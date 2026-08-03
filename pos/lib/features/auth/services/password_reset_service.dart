import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/server_client.dart';

class PasswordResetService {
  Future<bool> requestOtp(String username) async {
    final client = ServerClient.instance;
    if (!client.isConnected) return false;

    try {
      final res = await http
          .post(
            client.uri('/auth/request-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username.trim()}),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyOtp(String username, String otp) async {
    final client = ServerClient.instance;
    if (!client.isConnected) return false;

    try {
      final res = await http
          .post(
            client.uri('/auth/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username.trim(), 'otp': otp.trim()}),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resetPassword(
    String username,
    String otp,
    String newPassword,
  ) async {
    final client = ServerClient.instance;
    if (!client.isConnected) return false;

    try {
      final res = await http
          .post(
            client.uri('/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username.trim(),
              'otp': otp.trim(),
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Offline alternative to the OTP flow above — no email/SMS/API involved.
  /// [recoveryCode] is the one shown once when the shop was created (or
  /// since regenerated via Settings by the owner).
  Future<bool> recoverWithCode(
    String username,
    String recoveryCode,
    String newPassword,
  ) async {
    final client = ServerClient.instance;
    if (!client.isConnected) return false;

    try {
      final res = await http
          .post(
            client.uri('/auth/recover-with-code'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username.trim(),
              'recoveryCode': recoveryCode.trim(),
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
