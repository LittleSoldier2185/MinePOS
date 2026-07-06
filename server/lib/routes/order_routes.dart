import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../database.dart';
import '../utils.dart';

void registerOrderRoutes(Router router, AppDb db, ServerConfig config) {
  router.get('/orders/stats', (Request req) => _getStats(req, db, config));
  router.get('/orders', (Request req) => _getOrders(req, db, config));
  router.post('/orders', (Request req) => _createOrder(req, db, config));
}

// GET /orders?date=YYYY-MM-DD
Response _getOrders(Request req, AppDb db, ServerConfig config) {
  if (extractClaims(req, config.jwtSecret) == null) return unauthorized();
  final date = req.url.queryParameters['date'];
  final orders = db.getOrders(date: date);
  return jsonOk(orders.map((o) => o.toJson()).toList());
}

// GET /orders/stats?date=YYYY-MM-DD
Response _getStats(Request req, AppDb db, ServerConfig config) {
  if (extractClaims(req, config.jwtSecret) == null) return unauthorized();
  final date = req.url.queryParameters['date'];
  return jsonOk(db.getOrderStats(date: date));
}

// POST /orders
// Body: { paymentMethod, amountPaid?, items: [{ menuItemId, menuItemName,
//          menuItemCategory, price, quantity }] }
Future<Response> _createOrder(
    Request req, AppDb db, ServerConfig config) async {
  if (extractClaims(req, config.jwtSecret) == null) return unauthorized();

  final body = await parseJsonBody(req);
  if (body == null) return jsonError('Invalid JSON body');

  final paymentMethod = body['paymentMethod'] as String?;
  if (paymentMethod == null ||
      (paymentMethod != 'cash' && paymentMethod != 'promptpay')) {
    return jsonError('paymentMethod must be "cash" or "promptpay"');
  }

  final rawItems = body['items'];
  if (rawItems is! List || rawItems.isEmpty) {
    return jsonError('items must be a non-empty array');
  }

  final items = rawItems.cast<Map<String, dynamic>>();
  for (final item in items) {
    if (item['menuItemId'] == null ||
        item['menuItemName'] == null ||
        item['price'] == null ||
        item['quantity'] == null) {
      return jsonError(
          'Each item requires menuItemId, menuItemName, price, quantity');
    }
  }

  final amountPaid = (body['amountPaid'] as num?)?.toDouble();
  final order = db.createOrder(
    paymentMethod: paymentMethod,
    amountPaid: amountPaid,
    items: items,
  );
  return jsonOk(order.toJson(), status: 201);
}
