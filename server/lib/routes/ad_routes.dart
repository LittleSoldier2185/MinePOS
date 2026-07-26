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
  // Registered before the '/ads/<id>' PATCH so 'reorder' can't be swallowed
  // by that pattern.
  router.post('/ads/reorder', (Request req) => _reorder(req, db, config));
  router.patch('/ads/<id>', (Request req, String id) => _updateSlide(req, id, db, config));
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

// PATCH /ads/:id  { durationSeconds? , muted? } — durationSeconds applies to
// image/gif slides only, muted to video slides only; both are accepted
// independently so either can be updated without touching the other.
Future<Response> _updateSlide(
    Request req, String id, AppDb db, ServerConfig config) async {
  if (requireRoles(req, db, config.jwtSecret, _kAdEditors) == null) {
    return unauthorized();
  }
  final body = await parseJsonBody(req);
  if (body == null || (!body.containsKey('durationSeconds') && !body.containsKey('muted'))) {
    return jsonError('durationSeconds and/or muted is required');
  }
  if (body.containsKey('durationSeconds')) {
    final durationSeconds = (body['durationSeconds'] as num?)?.toInt();
    if (durationSeconds == null || durationSeconds <= 0) {
      return jsonError('durationSeconds must be a positive number');
    }
    db.updateAdSlideDuration(id, durationSeconds);
  }
  if (body.containsKey('muted')) {
    final muted = body['muted'] as bool?;
    if (muted == null) return jsonError('muted must be a boolean');
    db.updateAdSlideMuted(id, muted);
  }
  final updated = db.getAdSlide(id);
  if (updated == null) return notFound('Ad slide not found');
  CustomerDisplayHub.instance.broadcastAdSlides(db.getAdSlides());
  return jsonOk(updated.toJson());
}

// POST /ads/reorder  { order: [id, id, ...] } — full new slide order.
Future<Response> _reorder(Request req, AppDb db, ServerConfig config) async {
  if (requireRoles(req, db, config.jwtSecret, _kAdEditors) == null) {
    return unauthorized();
  }
  final body = await parseJsonBody(req);
  final order = (body?['order'] as List?)?.cast<String>();
  if (order == null) return jsonError('order (array of ids) is required');
  db.reorderAdSlides(order);
  final slides = db.getAdSlides();
  CustomerDisplayHub.instance.broadcastAdSlides(slides);
  return jsonOk(slides.map((s) => s.toJson()).toList());
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
