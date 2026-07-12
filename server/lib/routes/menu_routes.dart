import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../database.dart';
import '../utils.dart';

void registerMenuRoutes(Router router, AppDb db, ServerConfig config) {
  router.get('/menu', (Request req) => _getMenu(req, db, config));
  router.post('/menu', (Request req) => _createItem(req, db, config));
  router.put('/menu/<id>', (Request req, String id) => _updateItem(req, id, db, config));
  router.delete('/menu/<id>', (Request req, String id) => _deleteItem(req, id, db, config));
  router.patch('/menu/<id>/toggle', (Request req, String id) => _toggleItem(req, id, db, config));
}

// GET /menu
Response _getMenu(Request req, AppDb db, ServerConfig config) {
  if (requireAuth(req, db, config.jwtSecret) == null) return unauthorized();
  final items = db.getMenuItems();
  return jsonOk(items.map((i) => i.toJson()).toList());
}

const _kMenuManagers = {'owner', 'manager'};

// POST /menu  { name, category, price, available? }
Future<Response> _createItem(
    Request req, AppDb db, ServerConfig config) async {
  if (requireRoles(req, db, config.jwtSecret, _kMenuManagers) == null) {
    return unauthorized();
  }

  final body = await parseJsonBody(req);
  final name = (body?['name'] as String?)?.trim();
  final category = (body?['category'] as String?)?.trim();
  final price = (body?['price'] as num?)?.toDouble();

  if (name == null || name.isEmpty ||
      category == null || category.isEmpty ||
      price == null || price <= 0) {
    return jsonError('name, category and price (> 0) are required');
  }

  final available = body?['available'] as bool? ?? true;
  final imageBase64 = body?['imageBase64'] as String?;
  final hasSweetness = body?['hasSweetness'] as bool? ?? false;
  final nameTh = (body?['nameTh'] as String?)?.trim();
  final item = db.createMenuItem(
    name: name,
    category: category,
    price: price,
    available: available,
    imageBase64: imageBase64,
    hasSweetness: hasSweetness,
    nameTh: nameTh == null || nameTh.isEmpty ? null : nameTh,
  );
  return jsonOk(item.toJson(), status: 201);
}

// PUT /menu/:id  { name, category, price, available }
Future<Response> _updateItem(
    Request req, String id, AppDb db, ServerConfig config) async {
  if (requireRoles(req, db, config.jwtSecret, _kMenuManagers) == null) {
    return unauthorized();
  }

  final body = await parseJsonBody(req);
  final name = (body?['name'] as String?)?.trim();
  final category = (body?['category'] as String?)?.trim();
  final price = (body?['price'] as num?)?.toDouble();
  final available = body?['available'] as bool?;

  if (name == null || category == null || price == null || available == null) {
    return jsonError('name, category, price and available are required');
  }

  final imageBase64 = body?['imageBase64'] as String?;
  final hasSweetness = body?['hasSweetness'] as bool? ?? false;
  final nameTh = (body?['nameTh'] as String?)?.trim();
  final updated = db.updateMenuItem(
    id: id,
    name: name,
    category: category,
    price: price,
    available: available,
    imageBase64: imageBase64,
    hasSweetness: hasSweetness,
    nameTh: nameTh == null || nameTh.isEmpty ? null : nameTh,
  );
  if (updated == null) return notFound('Menu item not found');
  return jsonOk(updated.toJson());
}

// DELETE /menu/:id
Response _deleteItem(
    Request req, String id, AppDb db, ServerConfig config) {
  if (requireRoles(req, db, config.jwtSecret, _kMenuManagers) == null) {
    return unauthorized();
  }
  final deleted = db.deleteMenuItem(id);
  if (!deleted) return notFound('Menu item not found');
  return Response(204);
}

// PATCH /menu/:id/toggle
Response _toggleItem(
    Request req, String id, AppDb db, ServerConfig config) {
  if (requireRoles(req, db, config.jwtSecret, _kMenuManagers) == null) {
    return unauthorized();
  }
  final item = db.toggleMenuItem(id);
  if (item == null) return notFound('Menu item not found');
  return jsonOk(item.toJson());
}
