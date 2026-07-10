import 'package:bcrypt/bcrypt.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../database.dart';
import '../utils.dart';

void registerShopRoutes(Router router, AppDb db, ServerConfig config) {
  router.delete('/shop', (Request req) => _deleteShop(req, db, config));
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

  db.wipeShop();
  return jsonOk({'ok': true});
}
