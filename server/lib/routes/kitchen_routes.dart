import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../database.dart';
import '../kitchen_hub.dart';
import '../utils.dart';

void registerKitchenRoutes(Router router, AppDb db, ServerConfig config) {
  router.get('/ws/kitchen',
      wsAuthRoute(db, config.jwtSecret, (channel) => KitchenHub.instance.add(channel, db)));
}
