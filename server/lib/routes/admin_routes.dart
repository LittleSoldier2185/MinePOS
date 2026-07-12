import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../customer_display_hub.dart';
import '../database.dart';
import '../kitchen_hub.dart';
import '../presence_tracker.dart';
import '../server_log.dart';
import '../utils.dart';

const _kAdminViewers = {'owner', 'manager'};

/// [onRestart] defaults to exiting the whole process — correct when the
/// server is its own OS process (the CLI, or the bundled exe under
/// `LocalServerLauncher`, which relaunches it). A caller that runs the
/// server in-process instead (e.g. `server_launcher`, a GUI wrapping
/// `startMinePosServer()` directly) must pass its own callback, or this
/// would exit the whole host app, not just "the server".
void registerAdminRoutes(
  Router router,
  AppDb db,
  ServerConfig config, {
  void Function()? onRestart,
}) {
  router.post(
      '/admin/restart', (Request req) => _restart(req, db, config, onRestart ?? _exitProcess));
  router.get('/admin/presence', (Request req) => _presence(req, db, config));
}

void _exitProcess() {
  Future.delayed(const Duration(milliseconds: 200), () => exit(0));
}

// GET /admin/presence — owner/manager only. Snapshot of who's actively using
// the system right now: users seen making an authenticated request in the
// last [PresenceTracker.onlineWithin], plus how many kitchen-display and
// customer-display devices currently hold a live WebSocket open.
Response _presence(Request req, AppDb db, ServerConfig config) {
  if (requireRoles(req, db, config.jwtSecret, _kAdminViewers) == null) {
    return unauthorized();
  }
  return jsonOk({
    'onlineUsers': PresenceTracker.instance.onlineUsers(),
    'kitchenDisplays': KitchenHub.instance.count,
    'customerDisplays': CustomerDisplayHub.instance.count,
  });
}

// POST /admin/restart — owner-only. Triggers [restart] (see [registerAdminRoutes]
// for what that defaults to) after responding, so the caller gets its 200 back
// before anything actually goes down.
Response _restart(Request req, AppDb db, ServerConfig config, void Function() restart) {
  if (requireRoles(req, db, config.jwtSecret, {'owner'}) == null) {
    return unauthorized();
  }
  ServerLog.instance.log('Restart requested via Server Status screen.');
  restart();
  return jsonOk({'ok': true});
}
