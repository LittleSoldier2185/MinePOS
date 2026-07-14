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
  router.patch('/users/<id>',
      (Request req, String id) => _updateUser(req, id, db, config));
  router.post('/users/<id>/logout',
      (Request req, String id) => _forceLogout(req, id, db, config));
  router.delete('/users/<id>',
      (Request req, String id) => _deleteUser(req, id, db, config));
}

// GET /users  (owner only)
Response _listUsers(Request req, AppDb db, ServerConfig config) {
  if (requireAuth(req, db, config.jwtSecret, role: 'owner') == null) {
    return unauthorized();
  }
  return jsonOk(db.getAllUsers().map((u) => u.toJson()).toList());
}

// POST /users  { username, password, role, name?, email?, phone?, avatarBase64? }  (owner only)
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

  final name = (body?['name'] as String?)?.trim();
  final email = (body?['email'] as String?)?.trim();
  final phone = (body?['phone'] as String?)?.trim();
  final avatarBase64 = body?['avatarBase64'] as String?;
  db.createUser(
    username: username,
    password: password,
    role: role,
    name: name == null || name.isEmpty ? null : name,
    email: email == null || email.isEmpty ? null : email,
    phone: phone == null || phone.isEmpty ? null : phone,
    avatarBase64: avatarBase64,
  );
  return jsonOk(db.getUserByUsername(username)!.toJson(), status: 201);
}

// PATCH /users/:id  { active?, role?, password?, username?, confirmPassword?,
//                      name?, email?, phone?, avatarBase64? }  (owner only)
// name/email/phone/avatarBase64 are always sent together as one profile
// update (full replace, like the menu item edit form) — not
// security-sensitive like active/role/password, so no self-edit restriction
// applies to them; the owner can update their own info the same as anyone
// else's. Renaming (username) is security-sensitive since it's the login
// identity, so it requires the acting owner's own password
// (confirmPassword) regardless of whose account is being renamed — the
// owner may not know a *different* staff member's password, but always
// knows their own.
Future<Response> _updateUser(
    Request req, String idParam, AppDb db, ServerConfig config) async {
  final actor = requireAuth(req, db, config.jwtSecret, role: 'owner');
  if (actor == null) return unauthorized();

  final id = int.tryParse(idParam);
  if (id == null) return jsonError('Invalid user id');
  final target = db.getUserById(id);
  if (target == null) return notFound('User not found');

  final body = await parseJsonBody(req);
  final active = body?['active'] as bool?;
  final role = (body?['role'] as String?)?.trim().toLowerCase();
  final password = body?['password'] as String?;
  final newUsername = (body?['username'] as String?)?.trim().toLowerCase();
  final confirmPassword = body?['confirmPassword'] as String?;
  final hasProfileUpdate = body != null &&
      (body.containsKey('name') ||
          body.containsKey('email') ||
          body.containsKey('phone') ||
          body.containsKey('avatarBase64'));
  final isSelf = target.id == actor.id;

  if (active == null &&
      role == null &&
      password == null &&
      newUsername == null &&
      !hasProfileUpdate) {
    return jsonError('active, role, password, username, or profile fields required');
  }

  if (active != null) {
    if (isSelf && !active) {
      return jsonError('You cannot deactivate your own account');
    }
    db.setUserActive(id, active);
  }
  if (role != null) {
    if (!_validRoles.contains(role)) {
      return jsonError('role must be one of $_validRoles');
    }
    if (isSelf && role != 'owner') {
      return jsonError('You cannot change your own role');
    }
    db.setUserRole(id, role);
  }
  if (password != null) {
    if (password.length < 8) {
      return jsonError('password must be at least 8 characters');
    }
    db.updatePasswordHash(id, BCrypt.hashpw(password, BCrypt.gensalt()));
  }
  if (newUsername != null) {
    if (newUsername.isEmpty) {
      return jsonError('username cannot be empty');
    }
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return jsonError('Your password is required to change a username');
    }
    if (!BCrypt.checkpw(confirmPassword, actor.passwordHash)) {
      return unauthorized('Incorrect password');
    }
    final conflict = db.getUserByUsername(newUsername);
    if (conflict != null && conflict.id != id) {
      return jsonError('Username already exists', status: 409);
    }
    db.updateUsername(id, newUsername);
  }
  if (hasProfileUpdate) {
    final name = (body['name'] as String?)?.trim();
    final email = (body['email'] as String?)?.trim();
    final phone = (body['phone'] as String?)?.trim();
    final avatarBase64 = body['avatarBase64'] as String?;
    db.updateUserProfile(
      id,
      name: name == null || name.isEmpty ? null : name,
      email: email == null || email.isEmpty ? null : email,
      phone: phone == null || phone.isEmpty ? null : phone,
      avatarBase64: avatarBase64,
    );
  }

  return jsonOk(db.getUserById(id)!.toJson());
}

// POST /users/:id/logout  (owner only) — invalidates outstanding JWTs
Response _forceLogout(
    Request req, String idParam, AppDb db, ServerConfig config) {
  if (requireAuth(req, db, config.jwtSecret, role: 'owner') == null) {
    return unauthorized();
  }
  final id = int.tryParse(idParam);
  if (id == null) return jsonError('Invalid user id');
  final target = db.getUserById(id);
  if (target == null) return notFound('User not found');

  final updated = db.bumpTokenVersion(id);
  return jsonOk(updated!.toJson());
}

// DELETE /users/:id  (owner only)
Response _deleteUser(
    Request req, String idParam, AppDb db, ServerConfig config) {
  final actor = requireAuth(req, db, config.jwtSecret, role: 'owner');
  if (actor == null) return unauthorized();

  final id = int.tryParse(idParam);
  if (id == null) return jsonError('Invalid user id');
  if (id == actor.id) {
    return jsonError('You cannot delete your own account');
  }

  final deleted = db.deleteUser(id);
  if (!deleted) return notFound('User not found');
  return Response(204);
}
