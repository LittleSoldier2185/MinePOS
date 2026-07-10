import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import '../lib/config.dart';
import '../lib/database.dart';
import '../lib/mdns_service.dart';
import '../lib/routes/auth_routes.dart';
import '../lib/routes/customer_display_routes.dart';
import '../lib/routes/health_route.dart';
import '../lib/routes/kitchen_routes.dart';
import '../lib/routes/menu_routes.dart';
import '../lib/routes/order_routes.dart';
import '../lib/routes/user_routes.dart';
import '../lib/utils.dart';

Future<void> main() async {
  final config = await ServerConfig.load();
  final db = await AppDb.open(config);

  final router = Router();
  registerHealthRoute(router, db, config);
  registerAuthRoutes(router, db, config);
  registerMenuRoutes(router, db, config);
  registerOrderRoutes(router, db, config);
  registerUserRoutes(router, db, config);
  registerKitchenRoutes(router, db, config);
  registerCustomerDisplayRoutes(router, db, config);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(cors())
      .addHandler(router.call);

  final server = await io.serve(
    handler,
    InternetAddress.anyIPv4,
    config.port,
  );
  print('MinePOS server listening on http://0.0.0.0:${server.port}');

  final mdns = await MdnsService.create(
    serviceName: config.shopName,
    port: config.port,
  );
  await mdns.start();

  // Graceful shutdown on Ctrl-C.
  ProcessSignal.sigint.watch().first.then((_) async {
    print('\nShutting down…');
    await mdns.stop();
    await server.close(force: true);
    exit(0);
  });
}
