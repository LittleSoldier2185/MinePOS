import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../database.dart';
import '../menu_hub.dart';
import '../utils.dart';

void registerMenuRoutes(Router router, AppDb db, ServerConfig config) {
  router.get('/menu', (Request req) => _getMenu(req, db, config));
  router.post('/menu', (Request req) => _createItem(req, db, config));
  router.put('/menu/<id>', (Request req, String id) => _updateItem(req, id, db, config));
  router.delete('/menu/<id>', (Request req, String id) => _deleteItem(req, id, db, config));
  router.patch('/menu/<id>/toggle', (Request req, String id) => _toggleItem(req, id, db, config));
  router.get('/menu/categories/order', (Request req) => _getCategoryOrder(req, db, config));
  router.put('/menu/categories/order', (Request req) => _setCategoryOrder(req, db, config));
  router.put('/menu/categories/rename', (Request req) => _renameCategory(req, db, config));

  router.get('/ws/menu',
      wsAuthRoute(db, config.jwtSecret, (channel) => MenuHub.instance.add(channel, db)));
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
  MenuHub.instance.broadcastItemChanged(item);
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
  MenuHub.instance.broadcastItemChanged(updated);
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
  MenuHub.instance.broadcastItemDeleted(id);
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
  MenuHub.instance.broadcastItemChanged(item);
  return jsonOk(item.toJson());
}

// GET /menu/categories/order — any authenticated role (the Order Taking
// screen's category chips need this too, not just Menu Management).
Response _getCategoryOrder(Request req, AppDb db, ServerConfig config) {
  if (requireAuth(req, db, config.jwtSecret) == null) return unauthorized();
  return jsonOk({'order': db.getCategoryOrder()});
}

// PUT /menu/categories/order  { order: [category, ...] }
Future<Response> _setCategoryOrder(
    Request req, AppDb db, ServerConfig config) async {
  if (requireRoles(req, db, config.jwtSecret, _kMenuManagers) == null) {
    return unauthorized();
  }
  final body = await parseJsonBody(req);
  final order = body?['order'];
  if (order is! List || order.any((c) => c is! String)) {
    return jsonError('order must be an array of category names');
  }
  final list = order.cast<String>();
  db.setCategoryOrder(list);
  MenuHub.instance.broadcastCategoryOrderChanged(list);
  return jsonOk({'order': list});
}

// PUT /menu/categories/rename  { from, to }
// Renames every item currently in category [from] to [to] — a category is
// just a free-text field on each item, so this is a bulk update rather than
// a rename of some separate categories row.
Future<Response> _renameCategory(
    Request req, AppDb db, ServerConfig config) async {
  if (requireRoles(req, db, config.jwtSecret, _kMenuManagers) == null) {
    return unauthorized();
  }
  final body = await parseJsonBody(req);
  final from = (body?['from'] as String?)?.trim();
  final to = (body?['to'] as String?)?.trim();
  if (from == null || from.isEmpty || to == null || to.isEmpty) {
    return jsonError('from and to are required');
  }
  if (from == to) return jsonOk({'count': 0});

  final changed = db.renameCategory(from: from, to: to);
  for (final item in changed) {
    MenuHub.instance.broadcastItemChanged(item);
  }
  MenuHub.instance.broadcastCategoryOrderChanged(db.getCategoryOrder());
  return jsonOk({'count': changed.length});
}
