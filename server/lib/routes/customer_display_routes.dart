import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config.dart';
import '../customer_display_hub.dart';
import '../database.dart';

void registerCustomerDisplayRoutes(
    Router router, AppDb db, ServerConfig config) {
  // Cart contents aren't sensitive and this is LAN-only, so unlike
  // /ws/kitchen this channel doesn't require a token — a customer-facing
  // device shouldn't need to log in at all. A `station` query param marks a
  // connection as a cashier register publishing under that name instead of a
  // passive display; see CustomerDisplayHub.
  router.get('/ws/customer-display', (Request req) {
    final station = req.url.queryParameters['station'];
    return webSocketHandler((WebSocketChannel channel, String? protocol) {
      if (station != null && station.isNotEmpty) {
        CustomerDisplayHub.instance.addPublisher(channel, station);
      } else {
        CustomerDisplayHub.instance.addSubscriber(channel);
      }
    })(req);
  });
}
