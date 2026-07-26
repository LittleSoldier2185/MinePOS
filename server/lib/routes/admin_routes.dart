import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../customer_display_hub.dart';
import '../database.dart';
import '../kitchen_hub.dart';
import '../presence_tracker.dart';
import '../server_log.dart';
import '../utils.dart';
import 'admin_web_page.dart';

const _kAdminViewers = {'owner', 'manager'};

/// [onRestart] defaults to exiting the whole process. Every current
/// entrypoint (`bin/server.dart`, used by both the CLI and the exe
/// `LocalServerLauncher` bundles) overrides this with an in-process restart
/// instead — swapping the running server for a fresh one without ever
/// exiting — since nothing actually supervises this process to relaunch it
/// after an exit. A future caller that runs the server in-process (e.g. a
/// GUI wrapping `startMinePosServer()` directly) must pass its own callback
/// too, or the exit(0) fallback here would kill the whole host app, not just
/// "the server".
void registerAdminRoutes(
  Router router,
  AppDb db,
  ServerConfig config, {
  void Function()? onRestart,
}) {
  router.post(
      '/admin/restart', (Request req) => _restart(req, db, config, onRestart ?? _exitProcess));
  router.get('/admin/presence', (Request req) => _presence(req, db, config));
  router.get('/admin/config', (Request req) => _getConfig(req, db, config));
  router.patch('/admin/config', (Request req) => _patchConfig(req, db, config, onRestart ?? _exitProcess));
  router.get('/admin/logs', (Request req) => _logs(req, db, config));
  router.get('/admin', (Request req) => Response.ok(adminWebPageHtml, headers: {'content-type': 'text/html'}));
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

// GET /admin/config — owner-only. Current listen settings.
Response _getConfig(Request req, AppDb db, ServerConfig config) {
  if (requireRoles(req, db, config.jwtSecret, {'owner'}) == null) {
    return unauthorized();
  }
  return jsonOk({'port': config.port, 'bindAddress': config.bindAddress ?? 'any'});
}

// PATCH /admin/config — owner-only. Persists a new port/bind address to
// server.json (ServerConfig.persistListenConfig) and restarts so it takes
// effect — mirrors /admin/restart's respond-then-restart shape. Only meaningful
// for the CLI/bundled-exe entrypoint; mobile self-host never reads this file's
// bindAddress (see ServerConfig.bindAddress doc).
Future<Response> _patchConfig(
    Request req, AppDb db, ServerConfig config, void Function() restart) async {
  if (requireRoles(req, db, config.jwtSecret, {'owner'}) == null) {
    return unauthorized();
  }
  final body = await parseJsonBody(req);
  if (body == null) return jsonError('Invalid JSON body');

  final port = body['port'];
  if (port is! int || port < 1 || port > 65535) {
    return jsonError('port must be an integer between 1 and 65535');
  }

  final rawBindAddress = body['bindAddress'];
  String? bindAddress;
  if (rawBindAddress != null && rawBindAddress != 'any') {
    if (rawBindAddress is! String || InternetAddress.tryParse(rawBindAddress) == null) {
      return jsonError('bindAddress must be a valid IP address, or "any"');
    }
    bindAddress = rawBindAddress;
  }

  await ServerConfig.persistListenConfig(config.dataDir, port: port, bindAddress: bindAddress);
  ServerLog.instance.log(
      'Listen settings changed to ${bindAddress ?? "all interfaces"}:$port via admin dashboard — restarting.');
  restart();
  return jsonOk({'ok': true, 'restarting': true});
}

// GET /admin/logs?lines=300 — owner-only. Tail of the persisted server log,
// same file the in-app Server Status → View Logs screen reads directly off
// disk; this is the remote-access equivalent for the web dashboard.
Response _logs(Request req, AppDb db, ServerConfig config) {
  if (requireRoles(req, db, config.jwtSecret, {'owner'}) == null) {
    return unauthorized();
  }
  final want = int.tryParse(req.url.queryParameters['lines'] ?? '') ?? 300;
  final file = File(p.join(config.dataDir, 'server.log'));
  if (!file.existsSync()) return jsonOk({'lines': <String>[]});
  final allLines = file.readAsLinesSync();
  final start = allLines.length > want ? allLines.length - want : 0;
  return jsonOk({'lines': allLines.sublist(start)});
}
