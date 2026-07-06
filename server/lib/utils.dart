import 'dart:async';
import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

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

Map<String, dynamic>? extractClaims(Request req, String jwtSecret) {
  final auth = req.headers['authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) return null;
  final token = auth.substring(7);
  try {
    final jwt = JWT.verify(token, SecretKey(jwtSecret));
    final payload = jwt.payload;
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return null;
  } catch (_) {
    return null;
  }
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
