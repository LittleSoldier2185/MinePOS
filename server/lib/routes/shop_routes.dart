import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../database.dart';
import '../utils.dart';

const _kShopEditors = {'owner', 'manager'};

void registerShopRoutes(Router router, AppDb db, ServerConfig config) {
  router.get('/shop', (Request req) => _getShop(req, db, config));
  router.patch('/shop', (Request req) => _updateShop(req, db, config));
  router.delete('/shop', (Request req) => _deleteShop(req, db, config));
}

// GET /shop — any authenticated role (the receipt/printer needs this for
// every cashier, not just owner/manager).
Response _getShop(Request req, AppDb db, ServerConfig config) {
  if (requireAuth(req, db, config.jwtSecret) == null) return unauthorized();
  final shopConfig = db.getShopConfig();
  if (shopConfig == null) return notFound('Shop not configured');
  return jsonOk(shopConfig);
}

// PATCH /shop  { shopName, address?, taxId?, email?, receiptFooter?,
//                promptPayId?, promptPayLabel? }
// Owner/manager only. Full replace of the editable fields (matches
// setShopConfig's own upsert shape) rather than a partial patch.
Future<Response> _updateShop(Request req, AppDb db, ServerConfig config) async {
  if (requireRoles(req, db, config.jwtSecret, _kShopEditors) == null) {
    return unauthorized();
  }
  final body = await parseJsonBody(req);
  final shopName = (body?['shopName'] as String?)?.trim();
  if (shopName == null || shopName.isEmpty) {
    return jsonError('shopName is required');
  }
  db.setShopConfig(
    shopName: shopName,
    address: (body?['address'] as String?)?.trim(),
    taxId: (body?['taxId'] as String?)?.trim(),
    email: (body?['email'] as String?)?.trim(),
    receiptFooter: (body?['receiptFooter'] as String?)?.trim(),
    promptPayId: (body?['promptPayId'] as String?)?.trim(),
    promptPayLabel: (body?['promptPayLabel'] as String?)?.trim(),
  );
  return jsonOk(db.getShopConfig()!);
}

// DELETE /shop  { email, username, password }  (owner only)
// Permanently wipes the shop — accounts, menu, orders, shop config — and
// reopens the server for POST /setup, same as a from-scratch install.
// Requires re-entering the shop's own contact email (set during Create
// Shop), the acting owner's own username, and their password, on top of
// the owner-only JWT check, since this is irreversible and destroys every
// other user's data.
Future<Response> _deleteShop(
    Request req, AppDb db, ServerConfig config) async {
  final actor = requireAuth(req, db, config.jwtSecret, role: 'owner');
  if (actor == null) return unauthorized();

  final body = await parseJsonBody(req);
  final email = (body?['email'] as String?)?.trim();
  final username = (body?['username'] as String?)?.trim();
  final password = body?['password'] as String?;
  if (email == null ||
      email.isEmpty ||
      username == null ||
      username.isEmpty ||
      password == null ||
      password.isEmpty) {
    return jsonError('email, username and password are required');
  }

  final shopConfig = db.getShopConfig();
  final shopEmail = shopConfig?['email'] as String?;
  if (shopEmail == null ||
      shopEmail.trim().toLowerCase() != email.toLowerCase()) {
    return unauthorized('Email does not match this shop\'s registered email');
  }
  if (username.toLowerCase() != actor.username) {
    return unauthorized('Username does not match the signed-in owner');
  }
  if (!BCrypt.checkpw(password, actor.passwordHash)) {
    return unauthorized('Incorrect password');
  }

  final wipedAdFilenames = db.wipeShop();
  for (final filename in wipedAdFilenames) {
    try {
      await File(p.join(config.dataDir, 'ads', filename)).delete();
    } catch (_) {
      // Best-effort — a missing/already-gone file shouldn't block the rest
      // of the shop wipe from completing.
    }
  }
  return jsonOk({'ok': true});
}
