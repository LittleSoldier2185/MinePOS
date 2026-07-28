import 'dart:async';
import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'database.dart';
import 'presence_tracker.dart';

// ── JSON responses ─────────────────────────────────────────────────────────────

Response jsonOk(Object data, {int status = 200}) => Response(
      status,
      body: jsonEncode(data),
      headers: {'content-type': 'application/json'},
    );

Response jsonError(String message, {int status = 400}) => Response(
      status,
      body: jsonEncode({'error': message}),
      headers: {'content-type': 'application/json'},
    );

Response unauthorized([String message = 'Unauthorized']) =>
    jsonError(message, status: 401);

Response notFound([String message = 'Not found']) =>
    jsonError(message, status: 404);

// ── Request helpers ──────────────────────────────────────────────────────────

Future<Map<String, dynamic>?> parseJsonBody(Request req) async {
  try {
    final body = await req.readAsString();
    if (body.isEmpty) return null;
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  } catch (_) {
    return null;
  }
}

// ── JWT helpers ───────────────────────────────────────────────────────────────

/// Verifies a raw JWT's signature *and* cross-checks it against the current
/// DB state, so a deactivated user or a forced logout takes effect
/// immediately instead of waiting for the JWT to expire.
DbUser? verifyToken(String token, AppDb db, String jwtSecret, {String? role}) {
  Map<String, dynamic> claims;
  try {
    final jwt = JWT.verify(token, SecretKey(jwtSecret));
    final payload = jwt.payload;
    if (payload is! Map) return null;
    claims = Map<String, dynamic>.from(payload);
  } catch (_) {
    return null;
  }

  final id = int.tryParse(claims['sub'] as String? ?? '');
  final ver = claims['ver'] as int?;
  final iat = (claims['iat'] as num?)?.toInt();
  if (id == null || ver == null || iat == null) return null;

  final user = db.getUserById(id);
  if (user == null || !user.active || user.tokenVersion != ver) return null;
  if (role != null && user.role != role) return null;
  final deviceName = claims['dev'] as String? ?? 'Unknown device';

  // Owner sessions are persistent; every other role is logged out after
  // 30 minutes of inactivity, enforced here since the JWT's own expiry is
  // fixed at login and can't reset on activity.
  if (user.role != 'owner' &&
      PresenceTracker.instance.isIdleExpired(user.id, deviceName, iat)) {
    return null;
  }

  PresenceTracker.instance.touch(user.id, user.username, user.role, deviceName);
  PresenceTracker.instance.touchSession(user.id, deviceName, iat);
  return user;
}

/// Same as [verifyToken], reading the token from the request's bearer header.
DbUser? requireAuth(Request req, AppDb db, String jwtSecret, {String? role}) {
  final auth = req.headers['authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) return null;
  return verifyToken(auth.substring(7), db, jwtSecret, role: role);
}

/// Same as [requireAuth], but accepts any of several roles instead of a
/// single exact match (e.g. menu writes are allowed for owner *or* manager).
DbUser? requireRoles(
    Request req, AppDb db, String jwtSecret, Set<String> roles) {
  final user = requireAuth(req, db, jwtSecret);
  if (user == null || !roles.contains(user.role)) return null;
  return user;
}

// ── WebSocket helper ──────────────────────────────────────────────────────────

/// Wraps [onConnect] with the query-param-token auth check shared by every
/// `/ws/*` route (`/ws/orders`, `/ws/kitchen`, `/ws/menu`) — browsers can't
/// set custom headers on a WebSocket handshake, so the JWT travels as
/// `?token=` instead of the usual Authorization header.
Handler wsAuthRoute(
  AppDb db,
  String jwtSecret,
  void Function(WebSocketChannel channel) onConnect,
) {
  return (Request req) {
    final token = req.url.queryParameters['token'];
    if (token == null || verifyToken(token, db, jwtSecret) == null) {
      return unauthorized();
    }
    return webSocketHandler((WebSocketChannel channel, String? protocol) => onConnect(channel))(req);
  };
}

// ── CORS middleware ────────────────────────────────────────────────────────────

Middleware cors() => createMiddleware(
      requestHandler: (req) {
        if (req.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        return null;
      },
      responseHandler: (res) => res.change(headers: _corsHeaders),
    );

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};
