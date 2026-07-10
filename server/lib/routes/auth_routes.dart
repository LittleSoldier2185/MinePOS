import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../database.dart';
import '../utils.dart';

void registerAuthRoutes(Router router, AppDb db, ServerConfig config) {
  router.post('/auth/login', (Request req) => _login(req, db, config));
  router.post('/auth/request-otp', (Request req) => _requestOtp(req, db));
  router.post('/auth/verify-otp', (Request req) => _verifyOtp(req, db));
  router.post('/auth/reset-password',
      (Request req) => _resetPassword(req, db, config));
}

// POST /auth/login  { username, password }
Future<Response> _login(
    Request req, AppDb db, ServerConfig config) async {
  final body = await parseJsonBody(req);
  if (body == null) return jsonError('Invalid JSON body');

  final username = (body['username'] as String?)?.trim().toLowerCase();
  final password = body['password'] as String?;
  if (username == null || username.isEmpty || password == null || password.isEmpty) {
    return jsonError('username and password are required');
  }

  final user = db.getUserByUsername(username);
  if (user == null || !BCrypt.checkpw(password, user.passwordHash)) {
    return unauthorized('Invalid username or password');
  }
  if (!user.active) {
    return unauthorized('This account has been deactivated');
  }

  final ttl = user.role == 'owner'
      ? const Duration(days: 30)
      : const Duration(hours: 8);
  final token = JWT(
    {'sub': user.username, 'role': user.role, 'ver': user.tokenVersion},
  ).sign(SecretKey(config.jwtSecret), expiresIn: ttl);

  return jsonOk({'token': token, 'role': user.role, 'username': user.username});
}

// POST /auth/request-otp  { username }
Future<Response> _requestOtp(Request req, AppDb db) async {
  final body = await parseJsonBody(req);
  final username = (body?['username'] as String?)?.trim().toLowerCase();
  if (username == null || username.isEmpty) {
    return jsonError('username is required');
  }

  final user = db.getUserByUsername(username);
  if (user == null) {
    // Don't reveal whether user exists; just return ok.
    return jsonOk({'ok': true});
  }

  final otp = db.generateAndStoreOtp(username);
  // In production wire this to an email/SMS provider.
  print('OTP for "$username": $otp  (valid 10 min)');

  return jsonOk({'ok': true});
}

// POST /auth/verify-otp  { username, otp }
Future<Response> _verifyOtp(Request req, AppDb db) async {
  final body = await parseJsonBody(req);
  final username = (body?['username'] as String?)?.trim().toLowerCase();
  final otp = (body?['otp'] as String?)?.trim();
  if (username == null || otp == null) {
    return jsonError('username and otp are required');
  }

  final stored = db.getOtp(username);
  if (stored == null ||
      stored.otp != otp ||
      DateTime.now().isAfter(stored.expiresAt)) {
    return jsonError('Invalid or expired OTP', status: 422);
  }

  return jsonOk({'ok': true});
}

// POST /auth/reset-password  { username, otp, newPassword }
Future<Response> _resetPassword(
    Request req, AppDb db, ServerConfig config) async {
  final body = await parseJsonBody(req);
  final username = (body?['username'] as String?)?.trim().toLowerCase();
  final otp = (body?['otp'] as String?)?.trim();
  final newPassword = body?['newPassword'] as String?;

  if (username == null || otp == null || newPassword == null) {
    return jsonError('username, otp and newPassword are required');
  }
  if (newPassword.length < 8) {
    return jsonError('Password must be at least 8 characters');
  }

  final stored = db.getOtp(username);
  if (stored == null ||
      stored.otp != otp ||
      DateTime.now().isAfter(stored.expiresAt)) {
    return jsonError('Invalid or expired OTP', status: 422);
  }

  final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
  db.updatePasswordHash(username, hash);
  db.deleteOtp(username);

  return jsonOk({'ok': true});
}
