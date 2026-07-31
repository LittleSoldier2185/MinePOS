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

// Shared by upload/update: either an absolute `expiresAt` (ISO date) or a
// relative `expiresInDays` (from *now*, at save time) — whichever query
// param is present wins if both somehow are. Neither present means "leave
// running forever" (upload) or "don't touch" (update, see _updateSlide).
DateTime? _parseExpiry(Map<String, String> params) {
  final days = int.tryParse(params['expiresInDays'] ?? '');
  if (days != null) return DateTime.now().add(Duration(days: days));
  final raw = params['expiresAt'];
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

// POST /ads?ext=png&durationSeconds=8&name=BOGO+Latte&expiresInDays=7
// (or &expiresAt=2026-08-06) — body is the raw file bytes.
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
  final name = req.url.queryParameters['name']?.trim();
  final expiresAt = _parseExpiry(req.url.queryParameters);
  final transition = req.url.queryParameters['transition'];
  if (transition != null && !kAdTransitions.contains(transition)) {
    return jsonError('transition must be one of: ${kAdTransitions.join(', ')}');
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
    name: (name?.isEmpty ?? true) ? null : name,
    expiresAt: expiresAt,
    transition: transition ?? 'fade',
  );
  CustomerDisplayHub.instance.broadcastAdSlides(db.getAdSlides());
  return jsonOk(slide.toJson(), status: 201);
}

// PATCH /ads/:id  { durationSeconds?, muted?, name?, expiresAt?, expiresInDays?, transition? }
// durationSeconds applies to image/gif slides only, muted to video slides
// only; every field is independent so any subset can be updated at once.
// `expiresAt: null` (present but null) or `expiresInDays: 0` both clear the
// expiry — same "runs forever" meaning as never having set one.
Future<Response> _updateSlide(
    Request req, String id, AppDb db, ServerConfig config) async {
  if (requireRoles(req, db, config.jwtSecret, _kAdEditors) == null) {
    return unauthorized();
  }
  final body = await parseJsonBody(req);
  final recognized = {'durationSeconds', 'muted', 'name', 'expiresAt', 'expiresInDays', 'transition'};
  if (body == null || !recognized.any(body.containsKey)) {
    return jsonError('At least one of ${recognized.join(', ')} is required');
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
  if (body.containsKey('name')) {
    final name = (body['name'] as String?)?.trim();
    db.updateAdSlideName(id, (name?.isEmpty ?? true) ? null : name);
  }
  if (body.containsKey('transition')) {
    final transition = body['transition'] as String?;
    if (transition == null || !kAdTransitions.contains(transition)) {
      return jsonError('transition must be one of: ${kAdTransitions.join(', ')}');
    }
    db.updateAdSlideTransition(id, transition);
  }
  if (body.containsKey('expiresInDays')) {
    final days = (body['expiresInDays'] as num?)?.toInt();
    db.updateAdSlideExpiry(id, (days == null || days <= 0) ? null : DateTime.now().add(Duration(days: days)));
  } else if (body.containsKey('expiresAt')) {
    final raw = body['expiresAt'] as String?;
    db.updateAdSlideExpiry(id, raw == null ? null : DateTime.tryParse(raw));
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
