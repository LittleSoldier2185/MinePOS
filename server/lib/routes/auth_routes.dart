import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../database.dart';
import '../email_service.dart';
import '../server_log.dart';
import '../utils.dart';

void registerAuthRoutes(Router router, AppDb db, ServerConfig config) {
  router.post('/auth/login', (Request req) => _login(req, db, config));
  router.get('/auth/me', (Request req) => _me(req, db, config));
  router.post('/auth/request-otp', (Request req) => _requestOtp(req, db, config));
  router.post('/auth/verify-otp', (Request req) => _verifyOtp(req, db));
  router.post('/auth/reset-password',
      (Request req) => _resetPassword(req, db, config));
  router.post('/auth/recover-with-code', (Request req) => _recoverWithCode(req, db));
}

// GET /auth/me — validates the bearer token (signature, active flag,
// token_version) and returns the current user, same shape as /auth/login's
// response minus the token itself. Lets a client silently confirm a
// remembered session is still good (not expired/deactivated) before
// committing to auto-login, without needing to re-send a password.
Response _me(Request req, AppDb db, ServerConfig config) {
  final user = requireAuth(req, db, config.jwtSecret);
  if (user == null) return unauthorized();
  return jsonOk(user.toAuthJson());
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

  return jsonOk({'token': token, ...user.toAuthJson()});
}

// POST /auth/request-otp  { username }
Future<Response> _requestOtp(Request req, AppDb db, ServerConfig config) async {
  final body = await parseJsonBody(req);
  final username = (body?['username'] as String?)?.trim().toLowerCase();
  if (username == null || username.isEmpty) {
    return jsonError('username is required');
  }

  // The forgot-password screen's field is labeled "Username or Email" —
  // accept either. The OTP is always stored under the raw input string
  // ([username], below) regardless of which one matched, since that's the
  // exact string the client re-sends to verify-otp/reset-password too.
  final user = db.getUserByUsername(username) ?? db.getUserByEmail(username);
  if (user == null) {
    // Don't reveal whether user exists; just return ok.
    return jsonOk({'ok': true});
  }

  final otp = db.generateAndStoreOtp(username);

  // Real delivery when SMTP is configured and the account has an email on
  // file; otherwise the original console-only fallback (dev environments,
  // or a shop that hasn't set up SMTP yet) — so this never hard-locks
  // anyone out of resetting their password.
  var emailed = false;
  if (config.smtpConfigured && user.email != null && user.email!.isNotEmpty) {
    emailed = await EmailService(config).sendOtp(toEmail: user.email!, otp: otp);
  }

  if (emailed) {
    ServerLog.instance.log('OTP emailed for "$username"');
  } else {
    // Code stays console-only, same reasoning as the admin bootstrap password.
    print('OTP for "$username": $otp  (valid 10 min)');
    ServerLog.instance.log(
        'OTP requested for "$username" (email not sent — ${config.smtpConfigured ? 'no email on file' : 'SMTP not configured'}; code shown in console output only, not persisted)');
  }

  return jsonOk({'ok': true});
}

bool _otpValid(DbOtp? stored, String otp) =>
    stored != null && stored.otp == otp && !DateTime.now().isAfter(stored.expiresAt);

// POST /auth/verify-otp  { username, otp }
Future<Response> _verifyOtp(Request req, AppDb db) async {
  final body = await parseJsonBody(req);
  final username = (body?['username'] as String?)?.trim().toLowerCase();
  final otp = (body?['otp'] as String?)?.trim();
  if (username == null || otp == null) {
    return jsonError('username and otp are required');
  }

  if (!_otpValid(db.getOtp(username), otp)) {
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

  if (!_otpValid(db.getOtp(username), otp)) {
    return jsonError('Invalid or expired OTP', status: 422);
  }

  // Same username-or-email lookup as _requestOtp — the OTP is stored under
  // whatever raw string the client sent to request-otp, but the account
  // itself still has to be found by whichever field actually matched.
  final user = db.getUserByUsername(username) ?? db.getUserByEmail(username);
  if (user == null) return jsonError('Invalid or expired OTP', status: 422);

  final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
  db.updatePasswordHash(user.id, hash);
  db.deleteOtp(username);

  return jsonOk({'ok': true});
}

// POST /auth/recover-with-code  { username, recoveryCode, newPassword }
// Offline alternative to the OTP flow above — no email/SMS/API involved at
// all. `recoveryCode` is the one shown once at shop bootstrap (or since
// regenerated via Settings by an owner); anyone who has it can reset any
// named account's password, same trust model as physically knowing the
// admin bootstrap password.
Future<Response> _recoverWithCode(Request req, AppDb db) async {
  final body = await parseJsonBody(req);
  final username = (body?['username'] as String?)?.trim().toLowerCase();
  final recoveryCode = (body?['recoveryCode'] as String?)?.trim().toUpperCase();
  final newPassword = body?['newPassword'] as String?;

  if (username == null || username.isEmpty || recoveryCode == null || recoveryCode.isEmpty) {
    return jsonError('username and recoveryCode are required');
  }
  if (newPassword == null || newPassword.length < 8) {
    return jsonError('Password must be at least 8 characters');
  }

  if (!db.verifyRecoveryCode(recoveryCode)) {
    return jsonError('Invalid recovery code', status: 422);
  }

  final user = db.getUserByUsername(username) ?? db.getUserByEmail(username);
  if (user == null) return jsonError('No such account', status: 404);

  final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
  db.updatePasswordHash(user.id, hash);

  return jsonOk({'ok': true});
}
