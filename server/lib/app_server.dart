import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'config.dart';
import 'customer_display_hub.dart';
import 'database.dart';
import 'mdns_service.dart';
import 'routes/ad_routes.dart';
import 'routes/admin_routes.dart';
import 'routes/auth_routes.dart';
import 'routes/backup_routes.dart';
import 'routes/customer_display_routes.dart';
import 'routes/health_route.dart';
import 'routes/kitchen_routes.dart';
import 'routes/menu_routes.dart';
import 'routes/order_routes.dart';
import 'routes/promotion_routes.dart';
import 'routes/setup_routes.dart';
import 'routes/shop_routes.dart';
import 'routes/user_routes.dart';
import 'server_log.dart';
import 'utils.dart';

/// A running MinePOS server instance, returned by [startMinePosServer].
class RunningServer {
  RunningServer(this.httpServer, this.db, this.mdns);

  final HttpServer httpServer;
  final AppDb db;
  final MdnsService? mdns;

  Future<void> close() async {
    await mdns?.stop();
    await httpServer.close(force: true);
    db.close();
  }
}

/// Builds the full route pipeline and starts serving.
///
/// [bindAddress] defaults to [InternetAddress.anyIPv4] — the existing
/// CLI/desktop behavior (LAN-visible, other devices can connect). Callers
/// that need a loopback-only, single-device server (e.g. mobile self-host)
/// must pass [InternetAddress.loopbackIPv4] explicitly and [enableMdns]
/// false, since a shop broadcast over mDNS would defeat the point of being
/// unreachable from other devices.
Future<RunningServer> startMinePosServer({
  required ServerConfig config,
  InternetAddress? bindAddress,
  bool enableMdns = true,
  void Function()? onRestartRequested,
  void Function(List<int> bytes)? onRestoreRequested,
}) async {
  ServerLog.open(config.dataDir);
  final db = await AppDb.open(config);
  // A snapshot restored with "include ad media" carries the ad image/video
  // files inline — write them back out to the ads dir on this first boot.
  db.extractBundledAdMedia(p.join(config.dataDir, 'ads'));
  // Seeds the hub's cached ad-slide list from disk before any display
  // connects — otherwise a display that connects before the first upload
  // after a restart would see an empty list until something changed it.
  CustomerDisplayHub.instance.broadcastAdSlides(db.getAdSlides());

  final router = Router();
  registerHealthRoute(router, db, config);
  registerAuthRoutes(router, db, config);
  registerMenuRoutes(router, db, config);
  registerOrderRoutes(router, db, config);
  registerUserRoutes(router, db, config);
  registerKitchenRoutes(router, db, config);
  registerCustomerDisplayRoutes(router, db, config);
  registerSetupRoutes(router, db, config);
  registerShopRoutes(router, db, config);
  registerAdRoutes(router, db, config);
  registerPromotionRoutes(router, db, config);
  registerAdminRoutes(router, db, config, onRestart: onRestartRequested);
  registerBackupRoutes(router, db, config, onRestoreRequested: onRestoreRequested);

  final handler = Pipeline()
      .addMiddleware(logRequests(
        logger: (message, isError) =>
            ServerLog.instance.log(redactTokens(message)),
      ))
      .addMiddleware(cors())
      .addHandler(router.call);

  final resolvedBindAddress = bindAddress ?? InternetAddress.anyIPv4;
  final httpServer = await io.serve(handler, resolvedBindAddress, config.port);
  ServerLog.instance.log(
      'MinePOS server listening on http://${resolvedBindAddress.address}:${httpServer.port}');

  MdnsService? mdns;
  if (enableMdns) {
    mdns = await MdnsService.create(serviceName: config.shopName, port: config.port);
    await mdns.start();
  }

  return RunningServer(httpServer, db, mdns);
}
