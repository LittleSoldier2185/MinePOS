import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/api_client.dart';
import '../../../core/services/server_client.dart';

/// A promotion as configured in Settings. Which of the nullable mechanics
/// fields matter depends on [type] — see `PromotionService` (cashier-side)
/// for the evaluation logic that interprets these against a cart, and
/// `server/lib/database.dart`'s `DbPromotion` doc comment for the same
/// field-per-type breakdown server-side.
class Promotion {
  Promotion({
    required this.id,
    required this.name,
    required this.type,
    required this.active,
    required this.scopeType,
    this.scopeItemIds = const [],
    this.scopeCategories = const [],
    this.excludeItemIds = const [],
    this.percentValue,
    this.flatAmount,
    this.maxDiscountCap,
    this.minSpendAmount,
    this.bogoBuyQty,
    this.bogoGetQty,
    this.bogoGetDiscountPercent,
    this.comboPrice,
    this.tiered = const [],
    this.startDate,
    this.endDate,
    this.daysOfWeek,
    this.timeStart,
    this.timeEnd,
    this.requiresManagerApproval = false,
    this.approvalThresholdAmount,
    this.codes = const [],
  });

  final String id;
  final String name;
  final String type;
  final bool active;

  final String scopeType;
  final List<String> scopeItemIds;
  final List<String> scopeCategories;
  final List<String> excludeItemIds;

  final double? percentValue;
  final double? flatAmount;
  final double? maxDiscountCap;
  final double? minSpendAmount;
  final int? bogoBuyQty;
  final int? bogoGetQty;
  final double? bogoGetDiscountPercent;
  final double? comboPrice;
  final List<Map<String, dynamic>> tiered;

  final DateTime? startDate;
  final DateTime? endDate;
  final List<int>? daysOfWeek;
  final String? timeStart;
  final String? timeEnd;

  final bool requiresManagerApproval;
  final double? approvalThresholdAmount;

  final List<PromotionCode> codes;

  factory Promotion.fromJson(Map<String, dynamic> json) => Promotion(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    active: json['active'] as bool,
    scopeType: json['scopeType'] as String,
    scopeItemIds: (json['scopeItemIds'] as List).cast<String>(),
    scopeCategories:
        (json['scopeCategories'] as List?)?.cast<String>() ?? const [],
    excludeItemIds: (json['excludeItemIds'] as List).cast<String>(),
    percentValue: (json['percentValue'] as num?)?.toDouble(),
    flatAmount: (json['flatAmount'] as num?)?.toDouble(),
    maxDiscountCap: (json['maxDiscountCap'] as num?)?.toDouble(),
    minSpendAmount: (json['minSpendAmount'] as num?)?.toDouble(),
    bogoBuyQty: json['bogoBuyQty'] as int?,
    bogoGetQty: json['bogoGetQty'] as int?,
    bogoGetDiscountPercent: (json['bogoGetDiscountPercent'] as num?)
        ?.toDouble(),
    comboPrice: (json['comboPrice'] as num?)?.toDouble(),
    tiered: (json['tiered'] as List).cast<Map<String, dynamic>>(),
    startDate: json['startDate'] != null
        ? DateTime.parse(json['startDate'] as String)
        : null,
    endDate: json['endDate'] != null
        ? DateTime.parse(json['endDate'] as String)
        : null,
    daysOfWeek: (json['daysOfWeek'] as List?)?.cast<int>(),
    timeStart: json['timeStart'] as String?,
    timeEnd: json['timeEnd'] as String?,
    requiresManagerApproval: json['requiresManagerApproval'] as bool? ?? false,
    approvalThresholdAmount: (json['approvalThresholdAmount'] as num?)
        ?.toDouble(),
    codes: (json['codes'] as List)
        .map((c) => PromotionCode.fromJson(c as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toRequestJson() => {
    'name': name,
    'type': type,
    'active': active,
    'scopeType': scopeType,
    'scopeItemIds': scopeItemIds,
    'scopeCategories': scopeCategories,
    'excludeItemIds': excludeItemIds,
    'percentValue': percentValue,
    'flatAmount': flatAmount,
    'maxDiscountCap': maxDiscountCap,
    'minSpendAmount': minSpendAmount,
    'bogoBuyQty': bogoBuyQty,
    'bogoGetQty': bogoGetQty,
    'bogoGetDiscountPercent': bogoGetDiscountPercent,
    'comboPrice': comboPrice,
    'tiered': tiered,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'daysOfWeek': daysOfWeek,
    'timeStart': timeStart,
    'timeEnd': timeEnd,
    'requiresManagerApproval': requiresManagerApproval,
    'approvalThresholdAmount': approvalThresholdAmount,
  };

  /// Only [codes] is ever actually swapped in practice (after add/delete
  /// code) — every other field flows through the editor's own controllers/
  /// state instead of round-tripping through this object mid-edit.
  Promotion copyWith({List<PromotionCode>? codes}) => Promotion(
    id: id,
    name: name,
    type: type,
    active: active,
    scopeType: scopeType,
    scopeItemIds: scopeItemIds,
    scopeCategories: scopeCategories,
    excludeItemIds: excludeItemIds,
    percentValue: percentValue,
    flatAmount: flatAmount,
    maxDiscountCap: maxDiscountCap,
    minSpendAmount: minSpendAmount,
    bogoBuyQty: bogoBuyQty,
    bogoGetQty: bogoGetQty,
    bogoGetDiscountPercent: bogoGetDiscountPercent,
    comboPrice: comboPrice,
    tiered: tiered,
    startDate: startDate,
    endDate: endDate,
    daysOfWeek: daysOfWeek,
    timeStart: timeStart,
    timeEnd: timeEnd,
    requiresManagerApproval: requiresManagerApproval,
    approvalThresholdAmount: approvalThresholdAmount,
    codes: codes ?? this.codes,
  );
}

class PromotionCode {
  PromotionCode({
    required this.id,
    required this.promotionId,
    required this.code,
    this.maxUses,
    this.usedCount = 0,
  });

  final String id;
  final String promotionId;
  final String code;
  final int? maxUses;
  final int usedCount;

  factory PromotionCode.fromJson(Map<String, dynamic> json) => PromotionCode(
    id: json['id'] as String,
    promotionId: json['promotionId'] as String,
    code: json['code'] as String,
    maxUses: json['maxUses'] as int?,
    usedCount: json['usedCount'] as int,
  );
}

/// Settings → Promotions management: owner/manager CRUD against
/// `/promotions`, same HTTP-service shape as `AdService`/`ShopService`.
class PromotionAdminService {
  PromotionAdminService._();
  static final instance = PromotionAdminService._();

  Future<List<Promotion>> list() async {
    final res = await apiSend(
      () => http.get(
        ServerClient.instance.uri('/promotions'),
        headers: ServerClient.instance.headers,
      ),
    );
    final list = jsonDecode(res.body) as List;
    return list
        .map((j) => Promotion.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Promotion> create(Promotion promotion) async {
    final res = await apiSend(
      () => http.post(
        ServerClient.instance.uri('/promotions'),
        headers: ServerClient.instance.headers,
        body: jsonEncode(promotion.toRequestJson()),
      ),
    );
    return Promotion.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Promotion> update(String id, Promotion promotion) async {
    final res = await apiSend(
      () => http.patch(
        ServerClient.instance.uri('/promotions/$id'),
        headers: ServerClient.instance.headers,
        body: jsonEncode(promotion.toRequestJson()),
      ),
    );
    return Promotion.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> delete(String id) => apiSend(
    () => http.delete(
      ServerClient.instance.uri('/promotions/$id'),
      headers: ServerClient.instance.headers,
    ),
  );

  Future<PromotionCode> addCode(
    String promotionId,
    String code, {
    int? maxUses,
  }) async {
    final res = await apiSend(
      () => http.post(
        ServerClient.instance.uri('/promotions/$promotionId/codes'),
        headers: ServerClient.instance.headers,
        body: jsonEncode({'code': code, 'maxUses': maxUses}),
      ),
    );
    return PromotionCode.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Re-checks a manager/owner's own credentials to authorize an
  /// over-threshold discount at checkout (payment screen's approval sheet)
  /// — same shape as the Remove Shop re-auth flow, just checking role
  /// instead of matching a specific actor. Never issues a session/JWT.
  Future<({int userId, String name})> approve({
    required String username,
    required String password,
  }) async {
    final res = await apiSend(
      () => http.post(
        ServerClient.instance.uri('/promotions/approve'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (userId: body['userId'] as int, name: body['name'] as String);
  }

  Future<void> deleteCode(String promotionId, String codeId) => apiSend(
    () => http.delete(
      ServerClient.instance.uri('/promotions/$promotionId/codes/$codeId'),
      headers: ServerClient.instance.headers,
    ),
  );
}
