import 'package:bcrypt/bcrypt.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../database.dart';
import '../utils.dart';

const _validRoles = {'owner', 'manager', 'worker'};

void registerUserRoutes(Router router, AppDb db, ServerConfig config) {
  router.get('/users', (Request req) => _listUsers(req, db, config));
  router.post('/users', (Request req) => _createUser(req, db, config));
  router.patch('/users/<username>',
      (Request req, String username) => _updateUser(req, username, db, config));
  router.post('/users/<username>/logout',
      (Request req, String username) => _forceLogout(req, username, db, config));
  router.delete('/users/<username>',
      (Request req, String username) => _deleteUser(req, username, db, config));
}

// GET /users  (owner only)
Response _listUsers(Request req, AppDb db, ServerConfig config) {
  if (requireAuth(req, db, config.jwtSecret, role: 'owner') == null) {
    return unauthorized();
  }
  return jsonOk(db.getAllUsers().map((u) => u.toJson()).toList());
}

// POST /users  { username, password, role }  (owner only)
Future<Response> _createUser(
    Request req, AppDb db, ServerConfig config) async {
  if (requireAuth(req, db, config.jwtSecret, role: 'owner') == null) {
    return unauthorized();
  }

  final body = await parseJsonBody(req);
  final username = (body?['username'] as String?)?.trim().toLowerCase();
  final password = body?['password'] as String?;
  final role = (body?['role'] as String?)?.trim().toLowerCase();

  if (username == null || username.isEmpty) {
    return jsonError('username is required');
  }
  if (password == null || password.length < 8) {
    return jsonError('password must be at least 8 characters');
  }
  if (role == null || !_validRoles.contains(role)) {
    return jsonError('role must be one of $_validRoles');
  }
  if (db.getUserByUsername(username) != null) {
    return jsonError('Username already exists', status: 409);
  }

  db.createUser(username: username, password: password, role: role);
  return jsonOk(db.getUserByUsername(username)!.toJson(), status: 201);
}

// PATCH /users/:username  { active?, role?, password? }  (owner only)
Future<Response> _updateUser(
    Request req, String username, AppDb db, ServerConfig config) async {
  final actor = requireAuth(req, db, config.jwtSecret, role: 'owner');
  if (actor == null) return unauthorized();

  final target = db.getUserByUsername(username);
  if (target == null) return notFound('User not found');

  final body = await parseJsonBody(req);
  final active = body?['active'] as bool?;
  final role = (body?['role'] as String?)?.trim().toLowerCase();
  final password = body?['password'] as String?;
  final isSelf = username.toLowerCase() == actor.username;

  if (active == null && role == null && password == null) {
    return jsonError('active, role, or password is required');
  }

  if (active != null) {
    if (isSelf && !active) {
      return jsonError('You cannot deactivate your own account');
    }
    db.setUserActive(username, active);
  }
  if (role != null) {
    if (!_validRoles.contains(role)) {
      return jsonError('role must be one of $_validRoles');
    }
    if (isSelf && role != 'owner') {
      return jsonError('You cannot change your own role');
    }
    db.setUserRole(username, role);
  }
  if (password != null) {
    if (password.length < 8) {
      return jsonError('password must be at least 8 characters');
    }
    db.updatePasswordHash(username, BCrypt.hashpw(password, BCrypt.gensalt()));
  }

  return jsonOk(db.getUserByUsername(username)!.toJson());
}

// POST /users/:username/logout  (owner only) — invalidates outstanding JWTs
Response _forceLogout(
    Request req, String username, AppDb db, ServerConfig config) {
  if (requireAuth(req, db, config.jwtSecret, role: 'owner') == null) {
    return unauthorized();
  }
  final target = db.getUserByUsername(username);
  if (target == null) return notFound('User not found');

  final updated = db.bumpTokenVersion(username);
  return jsonOk(updated!.toJson());
}

// DELETE /users/:username  (owner only)
Response _deleteUser(
    Request req, String username, AppDb db, ServerConfig config) {
  final actor = requireAuth(req, db, config.jwtSecret, role: 'owner');
  if (actor == null) return unauthorized();

  if (username.toLowerCase() == actor.username) {
    return jsonError('You cannot delete your own account');
  }

  final deleted = db.deleteUser(username);
  if (!deleted) return notFound('User not found');
  return Response(204);
}
