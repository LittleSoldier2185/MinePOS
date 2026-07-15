import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../database.dart';
import '../server_log.dart';
import '../utils.dart';

void registerAuthRoutes(Router router, AppDb db, ServerConfig config) {
  router.post('/auth/login', (Request req) => _login(req, db, config));
  router.get('/auth/me', (Request req) => _me(req, db, config));
  router.post('/auth/request-otp', (Request req) => _requestOtp(req, db));
  router.post('/auth/verify-otp', (Request req) => _verifyOtp(req, db));
  router.post('/auth/reset-password',
      (Request req) => _resetPassword(req, db, config));
}

// GET /auth/me — validates the bearer token (signature, active flag,
// token_version) and returns the current user, same shape as /auth/login's
// response minus the token itself. Lets a client silently confirm a
// remembered session is still good (not expired/deactivated) before
// committing to auto-login, without needing to re-send a password.
Response _me(Request req, AppDb db, ServerConfig config) {
  final user = requireAuth(req, db, config.jwtSecret);
  if (user == null) return unauthorized();
  return jsonOk({'role': user.role, 'username': user.username, 'id': user.id});
}

// POST /auth/login  { username, password, deviceName }
Future<Response> _login(
    Request req, AppDb db, ServerConfig config) async {
  final body = await parseJsonBody(req);
  if (body == null) return jsonError('Invalid JSON body');

  final username = (body['username'] as String?)?.trim().toLowerCase();
  final password = body['password'] as String?;
  final deviceName = (body['deviceName'] as String?)?.trim();
  if (username == null || username.isEmpty || password == null || password.isEmpty) {
    return jsonError('username and password are required');
  }
  if (deviceName == null || deviceName.isEmpty) {
    return jsonError('deviceName is required');
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
  // 'dev' identifies which physical station this login is for — lets two
  // devices signed in as the same account show up as distinct entries in
  // presence tracking instead of one clobbering the other (see
  // PresenceTracker) and lets a cashier station tag its customer-display
  // broadcasts so a display can pick which station to mirror.
  final token = JWT(
    {
      'sub': user.id.toString(),
      'role': user.role,
      'ver': user.tokenVersion,
      'dev': deviceName,
    },
  ).sign(SecretKey(config.jwtSecret), expiresIn: ttl);

  return jsonOk({
    'token': token,
    'role': user.role,
    'username': user.username,
    'id': user.id,
  });
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
  // Code stays console-only, same reasoning as the admin bootstrap password.
  ServerLog.instance.log(
      'OTP requested for "$username" (code shown in console output only, not persisted)');

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

  final user = db.getUserByUsername(username);
  if (user == null) return jsonError('Invalid or expired OTP', status: 422);

  final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
  db.updatePasswordHash(user.id, hash);
  db.deleteOtp(username);

  return jsonOk({'ok': true});
}
