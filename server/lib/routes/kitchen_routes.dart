import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config.dart';
import '../database.dart';
import '../kitchen_hub.dart';
import '../utils.dart';

void registerKitchenRoutes(Router router, AppDb db, ServerConfig config) {
  // Browsers can't set custom headers on a WebSocket handshake, so the JWT
  // travels as a query param here instead of the usual Authorization header.
  router.get('/ws/kitchen', (Request req) {
    final token = req.url.queryParameters['token'];
    if (token == null || verifyToken(token, db, config.jwtSecret) == null) {
      return unauthorized();
    }
    return webSocketHandler((WebSocketChannel channel, String? protocol) {
      KitchenHub.instance.add(channel, db);
    })(req);
  });
}
