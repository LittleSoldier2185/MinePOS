import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../database.dart';
import '../utils.dart';

void registerSetupRoutes(Router router, AppDb db, ServerConfig config) {
  router.post('/setup', (Request req) => _setup(req, db, config));
}

// POST /setup  { shopName, address?, taxId?, email?, receiptFooter?,
//                adminUsername, adminPassword }
// One-time bootstrap: creates the shop's own details and its first owner
// account. Only works while the server has no users at all — once a shop
// is set up (via this route, or MINEPOS_ADMIN_USER/PASS at startup), it's
// permanently closed off, same as any other account creation from then on
// going through Staff Management instead.
Future<Response> _setup(Request req, AppDb db, ServerConfig config) async {
  if (db.hasAnyUser()) {
    return jsonError('This server already has a shop set up', status: 409);
  }

  final body = await parseJsonBody(req);
  final shopName = (body?['shopName'] as String?)?.trim();
  final adminUsername = (body?['adminUsername'] as String?)?.trim();
  final adminPassword = body?['adminPassword'] as String?;

  if (shopName == null || shopName.isEmpty) {
    return jsonError('shopName is required');
  }
  if (adminUsername == null || adminUsername.isEmpty) {
    return jsonError('adminUsername is required');
  }
  if (adminPassword == null || adminPassword.length < 6) {
    return jsonError('adminPassword must be at least 6 characters');
  }

  db.setShopConfig(
    shopName: shopName,
    address: (body?['address'] as String?)?.trim(),
    taxId: (body?['taxId'] as String?)?.trim(),
    email: (body?['email'] as String?)?.trim(),
    receiptFooter: (body?['receiptFooter'] as String?)?.trim(),
  );
  db.createUser(username: adminUsername, password: adminPassword, role: 'owner');

  // Shown to the client exactly once, right here — only the bcrypt hash is
  // ever persisted, so this is the only response that will ever carry the
  // raw code. The client must show it to the owner and tell them to save it.
  final recoveryCode = db.generateRecoveryCode();

  return jsonOk({'ok': true, 'recoveryCode': recoveryCode}, status: 201);
}
