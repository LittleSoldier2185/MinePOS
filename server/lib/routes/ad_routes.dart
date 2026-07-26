import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../config.dart';
import '../customer_display_hub.dart';
import '../database.dart';
import '../utils.dart';

const _kAdEditors = {'owner', 'manager'};
const _uuid = Uuid();

// Extension → (type, content-type). GIFs are 'image' — Flutter's Image
// widget already animates them natively, no separate video-like handling
// needed.
const _allowedExtensions = {
  'jpg': ('image', 'image/jpeg'),
  'jpeg': ('image', 'image/jpeg'),
  'png': ('image', 'image/png'),
  'gif': ('image', 'image/gif'),
  'mp4': ('video', 'video/mp4'),
  'webm': ('video', 'video/webm'),
  'mov': ('video', 'video/quicktime'),
};

void registerAdRoutes(Router router, AppDb db, ServerConfig config) {
  router.get('/ads', (Request req) => _list(req, db, config));
  router.post('/ads', (Request req) => _upload(req, db, config));
  router.patch('/ads/<id>', (Request req, String id) => _updateDuration(req, id, db, config));
  router.delete('/ads/<id>', (Request req, String id) => _delete(req, id, db, config));
  // No auth — mirrors /ws/customer-display's own reasoning (not sensitive,
  // LAN-only): the passive customer display never logs in, so it has no
  // token to send here at all.
  router.get('/ads/<id>/file', (Request req, String id) => _serveFile(req, id, db, config));
}

Directory _adsDir(ServerConfig config) => Directory(p.join(config.dataDir, 'ads'));

// GET /ads
Response _list(Request req, AppDb db, ServerConfig config) {
  if (requireAuth(req, db, config.jwtSecret) == null) return unauthorized();
  final slides = db.getAdSlides();
  return jsonOk(slides.map((s) => s.toJson()).toList());
}

// POST /ads?ext=png&durationSeconds=8 — body is the raw file bytes.
Future<Response> _upload(Request req, AppDb db, ServerConfig config) async {
  if (requireRoles(req, db, config.jwtSecret, _kAdEditors) == null) {
    return unauthorized();
  }

  final ext = req.url.queryParameters['ext']?.toLowerCase();
  final typeInfo = _allowedExtensions[ext];
  if (ext == null || typeInfo == null) {
    return jsonError('ext must be one of: ${_allowedExtensions.keys.join(', ')}');
  }
  final (type, _) = typeInfo;

  int? durationSeconds;
  final durationParam = req.url.queryParameters['durationSeconds'];
  if (type == 'image' && durationParam != null) {
    durationSeconds = int.tryParse(durationParam);
  }

  final bytes = await req.read().expand((chunk) => chunk).toList();
  if (bytes.isEmpty) return jsonError('Empty file body');

  final adsDir = _adsDir(config);
  await adsDir.create(recursive: true);
  final filename = '${_uuid.v4()}.$ext';
  await File(p.join(adsDir.path, filename)).writeAsBytes(bytes, flush: true);

  final slide = db.createAdSlide(
    type: type,
    filename: filename,
    durationSeconds: type == 'image' ? (durationSeconds ?? 8) : null,
  );
  CustomerDisplayHub.instance.broadcastAdSlides(db.getAdSlides());
  return jsonOk(slide.toJson(), status: 201);
}

// PATCH /ads/:id  { durationSeconds }  — image/gif slides only.
Future<Response> _updateDuration(
    Request req, String id, AppDb db, ServerConfig config) async {
  if (requireRoles(req, db, config.jwtSecret, _kAdEditors) == null) {
    return unauthorized();
  }
  final body = await parseJsonBody(req);
  final durationSeconds = (body?['durationSeconds'] as num?)?.toInt();
  if (durationSeconds == null || durationSeconds <= 0) {
    return jsonError('durationSeconds (> 0) is required');
  }
  final updated = db.updateAdSlideDuration(id, durationSeconds);
  if (updated == null) return notFound('Ad slide not found');
  CustomerDisplayHub.instance.broadcastAdSlides(db.getAdSlides());
  return jsonOk(updated.toJson());
}

// DELETE /ads/:id
Future<Response> _delete(
    Request req, String id, AppDb db, ServerConfig config) async {
  if (requireRoles(req, db, config.jwtSecret, _kAdEditors) == null) {
    return unauthorized();
  }
  final filename = db.deleteAdSlide(id);
  if (filename == null) return notFound('Ad slide not found');
  try {
    await File(p.join(_adsDir(config).path, filename)).delete();
  } catch (_) {
    // Best-effort — an already-missing file shouldn't fail the delete.
  }
  CustomerDisplayHub.instance.broadcastAdSlides(db.getAdSlides());
  return Response(204);
}

// GET /ads/:id/file — unauthenticated, whole-file (no Range support: these
// are short looping clips that always restart from the beginning, never
// scrubbed/seeked).
Future<Response> _serveFile(
    Request req, String id, AppDb db, ServerConfig config) async {
  final slide = db.getAdSlide(id);
  if (slide == null) return notFound('Ad slide not found');
  final file = File(p.join(_adsDir(config).path, slide.filename));
  if (!await file.exists()) return notFound('Ad slide file missing');

  final ext = p.extension(slide.filename).replaceFirst('.', '').toLowerCase();
  final contentType = _allowedExtensions[ext]?.$2 ?? 'application/octet-stream';
  return Response.ok(
    file.openRead(),
    headers: {'content-type': contentType},
  );
}
