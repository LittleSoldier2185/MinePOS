import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';

import '../config.dart';
import '../database.dart';
import '../utils.dart';

void registerHealthRoute(Router router, AppDb db, ServerConfig config) {
  router.get('/health', (Request req) {
    return jsonOk({
      'status': 'ok',
      'version': '1.0.0',
      'shopName': config.shopName,
    });
  });
}
