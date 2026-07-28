import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import '../config.dart';
import '../database.dart';
import '../utils.dart';

void registerBackupRoutes(
  Router router,
  AppDb db,
  ServerConfig config, {
  void Function(List<int> bytes)? onRestoreRequested,
}) {
  router.get('/admin/backup', (Request req) => _backup(req, db, config));
  router.post('/admin/restore', (Request req) => _restore(req, db, config, onRestoreRequested));
}

// GET /admin/backup — owner-only. Snapshots the whole database (accounts,
// menu, orders, shop config) via AppDb.exportSnapshotTo and streams it back
// as a downloadable file, for moving the shop to a new device (either saved
// to a file, or pulled directly by a new device during Restore).
Future<Response> _backup(Request req, AppDb db, ServerConfig config) async {
  if (requireAuth(req, db, config.jwtSecret, role: 'owner') == null) {
    return unauthorized();
  }

  final shopConfig = db.getShopConfig();
  final shopName = (shopConfig?['shopName'] as String?) ?? 'minepos';
  final safeName = shopName.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  final timestamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-');
  final downloadName = '$safeName-backup-$timestamp.db';

  // VACUUM INTO requires the target path to not already exist — a temp name
  // inside the data dir keeps this on the same filesystem/volume as the
  // live db (VACUUM INTO can't write cross-device) without colliding with
  // minepos.db itself.
  final tmpPath = p.join(config.dataDir, '.backup-$timestamp.db');
  final tmpFile = File(tmpPath);
  try {
    db.exportSnapshotTo(tmpPath);
    final bytes = await tmpFile.readAsBytes();
    return Response.ok(
      bytes,
      headers: {
        'content-type': 'application/octet-stream',
        'content-disposition': 'attachment; filename="$downloadName"',
      },
    );
  } finally {
    if (await tmpFile.exists()) await tmpFile.delete();
  }
}

// POST /admin/restore — body is the raw bytes of a MinePOS backup .db file.
// No auth required, same security model as POST /setup: safe only because
// it's gated on this server having no shop of its own yet (db.hasAnyUser()
// == false) — it can only ever bootstrap an empty server, exactly like
// /setup does with a filled-in form instead of an uploaded snapshot. It can
// never overwrite a live shop's data, on this server or any other.
Future<Response> _restore(
  Request req,
  AppDb db,
  ServerConfig config,
  void Function(List<int> bytes)? onRestoreRequested,
) async {
  if (db.hasAnyUser()) {
    return jsonError('This server already has a shop set up.', status: 409);
  }
  if (onRestoreRequested == null) {
    return jsonError('Restore is not supported by this server.', status: 501);
  }

  final bytes = await req.read().expand((chunk) => chunk).toList();

  // Validate before accepting: write to a throwaway temp file and open it
  // read-only, same sanity check the client does before uploading its own
  // picked file — never trust an unauthenticated upload without checking
  // it's actually a MinePOS backup and not something that would corrupt
  // this server's data dir.
  final tmpPath = p.join(config.dataDir, '.restore-upload.db');
  final tmpFile = File(tmpPath);
  try {
    await tmpFile.writeAsBytes(bytes, flush: true);
    final check = sqlite3.open(tmpPath, mode: OpenMode.readOnly);
    final tables = check
        .select("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((r) => r['name'] as String)
        .toSet();
    check.dispose();
    if (!tables.contains('shop_config') || !tables.contains('users')) {
      return jsonError('That file does not look like a MinePOS backup.');
    }
  } catch (_) {
    return jsonError('That file does not look like a MinePOS backup.');
  } finally {
    if (await tmpFile.exists()) await tmpFile.delete();
  }

  // Respond before the callback tears down the HTTP listener serving this
  // very request — same pattern POST /admin/restart already uses.
  onRestoreRequested(bytes);
  return jsonOk({'ok': true});
}
