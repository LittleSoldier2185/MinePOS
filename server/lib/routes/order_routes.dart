import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config.dart';
import '../database.dart';
import '../kitchen_hub.dart';
import '../order_hub.dart';
import '../utils.dart';

void registerOrderRoutes(Router router, AppDb db, ServerConfig config) {
  router.get('/orders/stats', (Request req) => _getStats(req, db, config));
  router.get('/orders', (Request req) => _getOrders(req, db, config));
  router.post('/orders', (Request req) => _createOrder(req, db, config));
  router.patch('/orders/<id>/status',
      (Request req, String id) => _updateStatus(req, id, db, config));
  router.patch('/orders/<id>/items/<itemId>/status',
      (Request req, String id, String itemId) =>
          _updateItemStatus(req, id, itemId, db, config));

  // Browsers can't set custom headers on a WebSocket handshake, so the JWT
  // travels as a query param here instead of the usual Authorization header.
  router.get('/ws/orders', (Request req) {
    final token = req.url.queryParameters['token'];
    if (token == null || verifyToken(token, db, config.jwtSecret) == null) {
      return unauthorized();
    }
    return webSocketHandler((WebSocketChannel channel, String? protocol) {
      OrderHub.instance.add(channel, db);
    })(req);
  });
}

// GET /orders?date=YYYY-MM-DD
Response _getOrders(Request req, AppDb db, ServerConfig config) {
  if (requireAuth(req, db, config.jwtSecret) == null) return unauthorized();
  final date = req.url.queryParameters['date'];
  final orders = db.getOrders(date: date);
  return jsonOk(orders.map((o) => o.toJson()).toList());
}

// GET /orders/stats?date=YYYY-MM-DD
Response _getStats(Request req, AppDb db, ServerConfig config) {
  if (requireAuth(req, db, config.jwtSecret) == null) return unauthorized();
  final date = req.url.queryParameters['date'];
  return jsonOk(db.getOrderStats(date: date));
}

// POST /orders
// Body: { paymentMethod, amountPaid?, items: [{ menuItemId, menuItemName,
//          menuItemCategory, price, quantity, discountAmount? }],
//         promotions?: [{ promotionId, discountAmount, codeUsed?,
//          approvedByUserId? }] }
// `promotions` mirrors `PromotionService.evaluate()`'s output client-side —
// same trust model as `items`' prices: the client already computed the
// discount, this just persists it (into `order_promotions`, incrementing
// any code's `used_count`) for the receipt/reports/audit trail.
Future<Response> _createOrder(
    Request req, AppDb db, ServerConfig config) async {
  final actor = requireAuth(req, db, config.jwtSecret);
  if (actor == null) return unauthorized();

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

  final rawPromotions = body['promotions'];
  final promotions =
      rawPromotions is List ? rawPromotions.cast<Map<String, dynamic>>() : const <Map<String, dynamic>>[];
  for (final promo in promotions) {
    if (promo['promotionId'] == null || promo['discountAmount'] == null) {
      return jsonError('Each promotion requires promotionId, discountAmount');
    }
  }

  final amountPaid = (body['amountPaid'] as num?)?.toDouble();
  final order = db.createOrder(
    paymentMethod: paymentMethod,
    amountPaid: amountPaid,
    items: items,
    promotions: promotions,
    createdByUserId: actor.id,
    createdByName: (actor.name?.isNotEmpty ?? false) ? actor.name! : actor.username,
  );
  KitchenHub.instance.broadcastOrderCreated(order);
  OrderHub.instance.broadcastOrderCreated(order);
  return jsonOk(order.toJson(), status: 201);
}

// PATCH /orders/:id/status  { status: "pending"|"preparing"|"ready"|"completed"|"cancelled", reason? }
// `reason` is required when status is "cancelled" — the chosen common reason,
// optionally with free-text detail appended (composed client-side).
Future<Response> _updateStatus(
    Request req, String id, AppDb db, ServerConfig config) async {
  if (requireAuth(req, db, config.jwtSecret) == null) return unauthorized();

  final orderId = int.tryParse(id);
  if (orderId == null) return jsonError('Invalid order id');

  final body = await parseJsonBody(req);
  final status = body?['status'] as String?;
  if (status == null || !kOrderStatuses.contains(status)) {
    return jsonError('status must be one of $kOrderStatuses');
  }

  String? reason;
  // A cancel is only safe while every item is still untouched — once the
  // kitchen has started (or finished) prep, the order's status has already
  // moved off 'pending' and cancelling would silently drop real work.
  if (status == 'cancelled') {
    final existing = db.getOrderById(orderId);
    if (existing == null) return notFound('Order not found');
    if (existing.status != 'pending') {
      return jsonError(
          'Order can only be cancelled while all items are still pending',
          status: 409);
    }
    reason = (body?['reason'] as String?)?.trim();
    if (reason == null || reason.isEmpty) {
      return jsonError('reason is required to cancel an order');
    }
  }

  final updated = db.updateOrderStatus(orderId, status, reason: reason);
  if (updated == null) return notFound('Order not found');
  KitchenHub.instance.broadcastOrderStatus(updated);
  OrderHub.instance.broadcastOrderStatus(updated);
  return jsonOk(updated.toJson());
}

// PATCH /orders/:id/items/:itemId/status  { status: "pending"|"preparing"|"ready" }
Future<Response> _updateItemStatus(Request req, String id, String itemId,
    AppDb db, ServerConfig config) async {
  if (requireAuth(req, db, config.jwtSecret) == null) return unauthorized();

  final orderId = int.tryParse(id);
  final orderItemId = int.tryParse(itemId);
  if (orderId == null || orderItemId == null) {
    return jsonError('Invalid order or item id');
  }

  final body = await parseJsonBody(req);
  final status = body?['status'] as String?;
  if (status == null || !kOrderItemStatuses.contains(status)) {
    return jsonError('status must be one of $kOrderItemStatuses');
  }

  final updated = db.updateOrderItemStatus(orderId, orderItemId, status);
  if (updated == null) return notFound('Order or item not found');
  KitchenHub.instance.broadcastItemStatus(updated, orderItemId);
  KitchenHub.instance.broadcastOrderStatus(updated);
  return jsonOk(updated.toJson());
}
