import 'package:bcrypt/bcrypt.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../database.dart';
import '../utils.dart';

const _kPromotionEditors = {'owner', 'manager'};

void registerPromotionRoutes(Router router, AppDb db, ServerConfig config) {
  router.get('/promotions', (Request req) => _list(req, db, config));
  router.post('/promotions', (Request req) => _create(req, db, config));
  router.patch('/promotions/<id>', (Request req, String id) => _update(req, id, db, config));
  router.delete('/promotions/<id>', (Request req, String id) => _delete(req, id, db, config));
  router.post('/promotions/<id>/codes', (Request req, String id) => _addCode(req, id, db, config));
  router.delete('/promotions/<id>/codes/<codeId>',
      (Request req, String id, String codeId) => _deleteCode(req, codeId, db, config));
  router.post('/promotions/validate-code', (Request req) => _validateCode(req, db, config));
  router.post('/promotions/approve', (Request req) => _approve(req, db, config));
}

// GET /promotions — any authenticated role (cashier devices need this to
// evaluate a cart).
Response _list(Request req, AppDb db, ServerConfig config) {
  if (requireAuth(req, db, config.jwtSecret) == null) return unauthorized();
  return jsonOk(db.getPromotions().map((p) => p.toJson()).toList());
}

const _kPromotionTypes = {'percent', 'flat', 'bogo', 'code', 'combo', 'min_spend', 'tiered'};
const _kScopeTypes = {'item', 'category', 'shop'};

/// Shared body → field extraction for create/update — both take an
/// identical shape, only create additionally requires `name`/`type`/
/// `scopeType` to be non-null (update always has them since it's a full
/// replace, same convention as `updateMenuItem`).
({
  String? name,
  String? type,
  bool active,
  String? scopeType,
  List<String> scopeItemIds,
  String? scopeCategory,
  List<String> excludeItemIds,
  double? percentValue,
  double? flatAmount,
  double? maxDiscountCap,
  double? minSpendAmount,
  int? bogoBuyQty,
  int? bogoGetQty,
  double? bogoGetDiscountPercent,
  double? comboPrice,
  List<Map<String, dynamic>> tiered,
  DateTime? startDate,
  DateTime? endDate,
  List<int>? daysOfWeek,
  String? timeStart,
  String? timeEnd,
  bool requiresManagerApproval,
  double? approvalThresholdAmount,
}) _extractFields(Map<String, dynamic> body) {
  return (
    name: (body['name'] as String?)?.trim(),
    type: body['type'] as String?,
    active: body['active'] as bool? ?? true,
    scopeType: body['scopeType'] as String?,
    scopeItemIds: (body['scopeItemIds'] as List?)?.cast<String>() ?? const [],
    scopeCategory: (body['scopeCategory'] as String?)?.trim(),
    excludeItemIds: (body['excludeItemIds'] as List?)?.cast<String>() ?? const [],
    percentValue: (body['percentValue'] as num?)?.toDouble(),
    flatAmount: (body['flatAmount'] as num?)?.toDouble(),
    maxDiscountCap: (body['maxDiscountCap'] as num?)?.toDouble(),
    minSpendAmount: (body['minSpendAmount'] as num?)?.toDouble(),
    bogoBuyQty: (body['bogoBuyQty'] as num?)?.toInt(),
    bogoGetQty: (body['bogoGetQty'] as num?)?.toInt(),
    bogoGetDiscountPercent: (body['bogoGetDiscountPercent'] as num?)?.toDouble(),
    comboPrice: (body['comboPrice'] as num?)?.toDouble(),
    tiered: (body['tiered'] as List?)?.cast<Map<String, dynamic>>() ?? const [],
    startDate: body['startDate'] != null ? DateTime.parse(body['startDate'] as String) : null,
    endDate: body['endDate'] != null ? DateTime.parse(body['endDate'] as String) : null,
    daysOfWeek: (body['daysOfWeek'] as List?)?.cast<int>(),
    timeStart: body['timeStart'] as String?,
    timeEnd: body['timeEnd'] as String?,
    requiresManagerApproval: body['requiresManagerApproval'] as bool? ?? false,
    approvalThresholdAmount: (body['approvalThresholdAmount'] as num?)?.toDouble(),
  );
}

// POST /promotions — owner/manager only. See `_extractFields` for the body
// shape; only `name`, `type` (one of `_kPromotionTypes`), and `scopeType`
// (one of `_kScopeTypes`) are strictly required — which of the rest matter
// depends on `type`, validated client-side by the Settings form, not
// re-validated per-type here (same trust level as menu item fields).
Future<Response> _create(Request req, AppDb db, ServerConfig config) async {
  if (requireRoles(req, db, config.jwtSecret, _kPromotionEditors) == null) {
    return unauthorized();
  }
  final body = await parseJsonBody(req);
  if (body == null) return jsonError('Invalid JSON body');
  final f = _extractFields(body);

  if (f.name == null || f.name!.isEmpty) return jsonError('name is required');
  if (f.type == null || !_kPromotionTypes.contains(f.type)) {
    return jsonError('type must be one of ${_kPromotionTypes.join(', ')}');
  }
  if (f.scopeType == null || !_kScopeTypes.contains(f.scopeType)) {
    return jsonError('scopeType must be one of ${_kScopeTypes.join(', ')}');
  }

  final promotion = db.createPromotion(
    name: f.name!,
    type: f.type!,
    active: f.active,
    scopeType: f.scopeType!,
    scopeItemIds: f.scopeItemIds,
    scopeCategory: f.scopeCategory,
    excludeItemIds: f.excludeItemIds,
    percentValue: f.percentValue,
    flatAmount: f.flatAmount,
    maxDiscountCap: f.maxDiscountCap,
    minSpendAmount: f.minSpendAmount,
    bogoBuyQty: f.bogoBuyQty,
    bogoGetQty: f.bogoGetQty,
    bogoGetDiscountPercent: f.bogoGetDiscountPercent,
    comboPrice: f.comboPrice,
    tiered: f.tiered,
    startDate: f.startDate,
    endDate: f.endDate,
    daysOfWeek: f.daysOfWeek,
    timeStart: f.timeStart,
    timeEnd: f.timeEnd,
    requiresManagerApproval: f.requiresManagerApproval,
    approvalThresholdAmount: f.approvalThresholdAmount,
  );
  return jsonOk(promotion.toJson(), status: 201);
}

// PATCH /promotions/:id — owner/manager only, full replace (same shape as
// POST).
Future<Response> _update(Request req, String id, AppDb db, ServerConfig config) async {
  if (requireRoles(req, db, config.jwtSecret, _kPromotionEditors) == null) {
    return unauthorized();
  }
  final body = await parseJsonBody(req);
  if (body == null) return jsonError('Invalid JSON body');
  final f = _extractFields(body);

  if (f.name == null || f.name!.isEmpty) return jsonError('name is required');
  if (f.type == null || !_kPromotionTypes.contains(f.type)) {
    return jsonError('type must be one of ${_kPromotionTypes.join(', ')}');
  }
  if (f.scopeType == null || !_kScopeTypes.contains(f.scopeType)) {
    return jsonError('scopeType must be one of ${_kScopeTypes.join(', ')}');
  }

  final updated = db.updatePromotion(
    id: id,
    name: f.name!,
    type: f.type!,
    active: f.active,
    scopeType: f.scopeType!,
    scopeItemIds: f.scopeItemIds,
    scopeCategory: f.scopeCategory,
    excludeItemIds: f.excludeItemIds,
    percentValue: f.percentValue,
    flatAmount: f.flatAmount,
    maxDiscountCap: f.maxDiscountCap,
    minSpendAmount: f.minSpendAmount,
    bogoBuyQty: f.bogoBuyQty,
    bogoGetQty: f.bogoGetQty,
    bogoGetDiscountPercent: f.bogoGetDiscountPercent,
    comboPrice: f.comboPrice,
    tiered: f.tiered,
    startDate: f.startDate,
    endDate: f.endDate,
    daysOfWeek: f.daysOfWeek,
    timeStart: f.timeStart,
    timeEnd: f.timeEnd,
    requiresManagerApproval: f.requiresManagerApproval,
    approvalThresholdAmount: f.approvalThresholdAmount,
  );
  if (updated == null) return notFound('Promotion not found');
  return jsonOk(updated.toJson());
}

// DELETE /promotions/:id — owner/manager only.
Response _delete(Request req, String id, AppDb db, ServerConfig config) {
  if (requireRoles(req, db, config.jwtSecret, _kPromotionEditors) == null) {
    return unauthorized();
  }
  final deleted = db.deletePromotion(id);
  if (!deleted) return notFound('Promotion not found');
  return Response(204);
}

// POST /promotions/:id/codes  { code, maxUses? } — owner/manager only.
Future<Response> _addCode(Request req, String id, AppDb db, ServerConfig config) async {
  if (requireRoles(req, db, config.jwtSecret, _kPromotionEditors) == null) {
    return unauthorized();
  }
  if (db.getPromotion(id) == null) return notFound('Promotion not found');

  final body = await parseJsonBody(req);
  final code = (body?['code'] as String?)?.trim();
  if (code == null || code.isEmpty) return jsonError('code is required');
  final maxUses = (body?['maxUses'] as num?)?.toInt();

  final created = db.addPromotionCode(id, code, maxUses: maxUses);
  return jsonOk(created.toJson(), status: 201);
}

// DELETE /promotions/:id/codes/:codeId — owner/manager only.
Response _deleteCode(Request req, String codeId, AppDb db, ServerConfig config) {
  if (requireRoles(req, db, config.jwtSecret, _kPromotionEditors) == null) {
    return unauthorized();
  }
  final deleted = db.deletePromotionCode(codeId);
  if (!deleted) return notFound('Code not found');
  return Response(204);
}

// POST /promotions/validate-code  { code } — any authenticated role. Backs
// the cashier's "enter a discount code" UX: distinguishes not-found from
// found-but-inactive/expired/used-up so the app can show a specific message
// instead of a generic failure.
Future<Response> _validateCode(Request req, AppDb db, ServerConfig config) async {
  if (requireAuth(req, db, config.jwtSecret) == null) return unauthorized();
  final body = await parseJsonBody(req);
  final code = (body?['code'] as String?)?.trim();
  if (code == null || code.isEmpty) return jsonError('code is required');

  final found = db.findPromotionByCode(code);
  if (found == null) return jsonError('Code not found', status: 404);

  final (promotion: promotion, code: dbCode) = found;
  if (!promotion.active) return jsonError('This code is no longer active', status: 409);
  if (dbCode.maxUses != null && dbCode.usedCount >= dbCode.maxUses!) {
    return jsonError('This code has already been used up', status: 409);
  }
  return jsonOk({'promotion': promotion.toJson(), 'code': dbCode.toJson()});
}

// POST /promotions/approve  { username, password } — re-checks a manager or
// owner's own credentials to authorize an over-threshold discount, same
// shape as the Remove Shop re-auth flow (`shop_routes.dart`'s
// `_deleteShop`), just checking role instead of matching a specific actor.
// Never issues a JWT — this only answers "is this a valid manager/owner"
// for the cashier app to record `approvedByUserId` locally.
Future<Response> _approve(Request req, AppDb db, ServerConfig config) async {
  final body = await parseJsonBody(req);
  final username = (body?['username'] as String?)?.trim();
  final password = body?['password'] as String?;
  if (username == null || username.isEmpty || password == null || password.isEmpty) {
    return jsonError('username and password are required');
  }

  final user = db.getUserByUsername(username.toLowerCase());
  if (user == null || !user.active || !_kPromotionEditors.contains(user.role)) {
    return unauthorized('No such manager/owner account');
  }
  if (!BCrypt.checkpw(password, user.passwordHash)) {
    return unauthorized('Incorrect password');
  }
  return jsonOk({'userId': user.id, 'name': user.name ?? user.username});
}
