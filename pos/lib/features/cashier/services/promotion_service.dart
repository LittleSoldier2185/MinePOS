import '../../manager/services/promotion_admin_service.dart';
import '../models/menu_item.dart';
import '../models/order_item.dart';

/// One promotion that matched the current cart, with the ฿ amount it's
/// worth. [needsApproval] is true when [AppliedPromotion] hasn't yet
/// cleared [Promotion.requiresManagerApproval] — the caller must show an
/// approval prompt and re-evaluate with that promotion's id added to
/// `approvedPromotionIds` before its discount counts toward the total.
class AppliedPromotion {
  AppliedPromotion({
    required this.promotion,
    required this.discountAmount,
    required this.needsApproval,
    this.codeUsed,
  });

  final Promotion promotion;
  final double discountAmount;
  final bool needsApproval;
  final String? codeUsed;
}

/// Result of [PromotionService.evaluate] — [applied] already counts toward
/// the order total; [pendingApproval] doesn't yet (shown to the cashier as
/// "needs manager approval" prompts instead).
class PromotionEvaluation {
  PromotionEvaluation({required this.applied, required this.pendingApproval});

  final List<AppliedPromotion> applied;
  final List<AppliedPromotion> pendingApproval;

  double get totalDiscount => applied.fold(0.0, (s, a) => s + a.discountAmount);
}

/// Evaluates which configured promotions apply to a cart and how much
/// they're worth — pure functions over (cart, promotion list, code, time),
/// no server round-trip, matching the app's existing trust model where the
/// cashier device is already authoritative for order pricing.
///
/// Stacking order (deliberate, not incidental — see the design doc this
/// followed): BOGO first, then combo/tiered/min-spend/flat/percent (each
/// independent of the others, but percent's own scope-subtotal is reduced
/// by whatever BOGO already took off those same items — [_bogoDiscountByItemId]
/// is how that gets threaded through), then a discount code last, layered
/// on top of everything already active.
class PromotionService {
  PromotionService._();

  static PromotionEvaluation evaluate({
    required List<OrderItem> items,
    required List<Promotion> promotions,
    String? enteredCode,
    Set<String> approvedPromotionIds = const {},
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final applied = <AppliedPromotion>[];
    final pending = <AppliedPromotion>[];
    final bogoDiscountByItemId = <String, double>{};

    void record(Promotion p, double discount, {String? codeUsed}) {
      if (discount <= 0) return;
      final needsApproval =
          p.requiresManagerApproval &&
          !approvedPromotionIds.contains(p.id) &&
          (p.approvalThresholdAmount == null ||
              discount > p.approvalThresholdAmount!);
      final entry = AppliedPromotion(
        promotion: p,
        discountAmount: discount,
        needsApproval: needsApproval,
        codeUsed: codeUsed,
      );
      (needsApproval ? pending : applied).add(entry);
    }

    final candidates = promotions
        .where((p) => p.active && _isInSchedule(p, effectiveNow))
        .toList();

    for (final p in candidates.where((p) => p.type == 'bogo')) {
      record(p, _evaluateBogo(p, items, bogoDiscountByItemId));
    }
    for (final p in candidates.where((p) => p.type == 'combo')) {
      record(p, _evaluateCombo(p, items));
    }
    for (final p in candidates.where((p) => p.type == 'tiered')) {
      record(p, _evaluateTiered(p, items));
    }
    for (final p in candidates.where((p) => p.type == 'min_spend')) {
      record(p, _evaluateMinSpend(p, items, bogoDiscountByItemId));
    }
    for (final p in candidates.where((p) => p.type == 'flat')) {
      record(p, _evaluateFlat(p, items));
    }
    for (final p in candidates.where((p) => p.type == 'percent')) {
      record(p, _evaluatePercent(p, items, bogoDiscountByItemId));
    }
    if (enteredCode != null && enteredCode.trim().isNotEmpty) {
      final normalized = enteredCode.trim().toUpperCase();
      for (final p in candidates.where((p) => p.type == 'code')) {
        final matches = p.codes.where(
          (c) => c.code.toUpperCase() == normalized,
        );
        if (matches.isEmpty) continue;
        final code = matches.first;
        // Best-effort client-side check against the last-fetched usage
        // count — the server re-checks authoritatively at order creation
        // regardless (see `ad_routes.dart`-style validate-code route).
        if (code.maxUses != null && code.usedCount >= code.maxUses!) continue;
        final discount = p.percentValue != null
            ? _evaluatePercent(p, items, bogoDiscountByItemId)
            : (p.flatAmount != null ? _evaluateFlat(p, items) : 0.0);
        record(p, discount, codeUsed: code.code);
      }
    }

    return PromotionEvaluation(applied: applied, pendingApproval: pending);
  }

  /// Per-item discount attribution for the receipt/order_items — only BOGO
  /// discount is attributed back to specific menu items (it's inherently
  /// per-unit); percent/flat/combo/tiered/code discounts are order-level
  /// only, shown as their own receipt line rather than split across items.
  static Map<String, double> bogoDiscountByItemId(
    List<OrderItem> items,
    List<Promotion> promotions, {
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final byId = <String, double>{};
    for (final p in promotions.where(
      (p) => p.type == 'bogo' && p.active && _isInSchedule(p, effectiveNow),
    )) {
      _evaluateBogo(p, items, byId);
    }
    return byId;
  }
}

bool _matchesScope(Promotion p, MenuItem menuItem) {
  if (p.excludeItemIds.contains(menuItem.id)) return false;
  switch (p.scopeType) {
    case 'item':
      return p.scopeItemIds.contains(menuItem.id);
    case 'category':
      return p.scopeCategories.contains(menuItem.category);
    default:
      return true; // 'shop'
  }
}

double _scopeMatchingSubtotal(Promotion p, List<OrderItem> items) => items
    .where((i) => _matchesScope(p, i.menuItem))
    .fold(0.0, (s, i) => s + i.subtotal);

bool _isInSchedule(Promotion p, DateTime now) {
  if (p.startDate != null) {
    final startOfDay = DateTime(
      p.startDate!.year,
      p.startDate!.month,
      p.startDate!.day,
    );
    if (now.isBefore(startOfDay)) return false;
  }
  if (p.endDate != null) {
    final endOfDay = DateTime(
      p.endDate!.year,
      p.endDate!.month,
      p.endDate!.day,
      23,
      59,
      59,
    );
    if (now.isAfter(endOfDay)) return false;
  }
  if (p.daysOfWeek != null && p.daysOfWeek!.isNotEmpty) {
    // 0=Monday..6=Sunday (`DateTime.weekday - 1`) — must match the
    // Settings editor's day-chip encoding exactly (see
    // `promotion_editor_screen.dart`'s day-of-week `List.generate`).
    final todayIndex = now.weekday - 1;
    if (!p.daysOfWeek!.contains(todayIndex)) return false;
  }
  if (p.timeStart != null || p.timeEnd != null) {
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = p.timeStart != null ? _parseHHmm(p.timeStart!) : 0;
    final endMinutes = p.timeEnd != null
        ? _parseHHmm(p.timeEnd!)
        : (24 * 60 - 1);
    if (nowMinutes < startMinutes || nowMinutes > endMinutes) return false;
  }
  return true;
}

int _parseHHmm(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

/// Buy [Promotion.bogoBuyQty], get [Promotion.bogoGetQty] at
/// [Promotion.bogoGetDiscountPercent] off (100 = free). Qualifying units
/// (one per quantity, across every matching line) are sorted priciest
/// first and chunked into complete groups of buyQty+getQty; within each
/// complete group, the *cheapest* getQty units (the tail, since the list
/// is sorted descending) receive the discount — the standard "discount
/// applies to the cheaper item(s)" BOGO convention, so a shop's margin on
/// its priciest items in a qualifying group is always protected. A trailing
/// partial group (not enough units left to fill buyQty+getQty) gets no
/// discount from this promotion.
double _evaluateBogo(
  Promotion p,
  List<OrderItem> items,
  Map<String, double> bogoDiscountByItemId,
) {
  final buyQty = p.bogoBuyQty ?? 0;
  final getQty = p.bogoGetQty ?? 0;
  final discountPercent = p.bogoGetDiscountPercent ?? 0;
  if (buyQty <= 0 || getQty <= 0 || discountPercent <= 0) return 0;
  final groupSize = buyQty + getQty;

  final units = <MapEntry<String, double>>[];
  for (final item in items) {
    if (!_matchesScope(p, item.menuItem)) continue;
    for (var i = 0; i < item.quantity; i++) {
      units.add(MapEntry(item.menuItem.id, item.menuItem.price));
    }
  }
  units.sort((a, b) => b.value.compareTo(a.value));

  double total = 0;
  for (var i = 0; i + groupSize <= units.length; i += groupSize) {
    final group = units.sublist(i, i + groupSize);
    for (final unit in group.sublist(buyQty)) {
      final discount = unit.value * (discountPercent / 100);
      total += discount;
      bogoDiscountByItemId[unit.key] =
          (bogoDiscountByItemId[unit.key] ?? 0) + discount;
    }
  }
  return total;
}

/// [scope]'s subtotal times [Promotion.percentValue]%, net of whatever
/// BOGO already discounted off those same items (so stacking a percent
/// promo on top of a BOGO doesn't double-count the BOGO'd portion), capped
/// at [Promotion.maxDiscountCap] if set.
double _evaluatePercent(
  Promotion p,
  List<OrderItem> items,
  Map<String, double> bogoDiscountByItemId,
) {
  final percent = p.percentValue ?? 0;
  if (percent <= 0) return 0;
  var subtotal = 0.0;
  for (final item in items) {
    if (!_matchesScope(p, item.menuItem)) continue;
    final bogoTaken = bogoDiscountByItemId[item.menuItem.id] ?? 0;
    final net = item.subtotal - bogoTaken;
    subtotal += net > 0 ? net : 0;
  }
  var discount = subtotal * percent / 100;
  if (p.maxDiscountCap != null && discount > p.maxDiscountCap!)
    discount = p.maxDiscountCap!;
  return discount;
}

/// A flat ฿ amount off the scope's subtotal — never more than that
/// subtotal itself (a promotion can't push a cart negative).
double _evaluateFlat(Promotion p, List<OrderItem> items) {
  final amount = p.flatAmount ?? 0;
  if (amount <= 0) return 0;
  final subtotal = _scopeMatchingSubtotal(p, items);
  if (subtotal <= 0) return 0;
  return amount > subtotal ? subtotal : amount;
}

double _evaluateMinSpend(
  Promotion p,
  List<OrderItem> items,
  Map<String, double> bogoDiscountByItemId,
) {
  final threshold = p.minSpendAmount ?? 0;
  final subtotal = _scopeMatchingSubtotal(p, items);
  if (subtotal < threshold) return 0;
  if (p.percentValue != null)
    return _evaluatePercent(p, items, bogoDiscountByItemId);
  if (p.flatAmount != null) return _evaluateFlat(p, items);
  return 0;
}

/// Fixed bundle price for one of each of [Promotion.scopeItemIds] — the
/// number of complete bundles formable is limited by whichever required
/// item has the smallest quantity in the cart (missing any required item
/// entirely means zero bundles).
double _evaluateCombo(Promotion p, List<OrderItem> items) {
  if (p.comboPrice == null || p.scopeItemIds.isEmpty) return 0;
  var bundles = -1;
  var bundlePrice = 0.0;
  for (final id in p.scopeItemIds) {
    OrderItem? match;
    for (final item in items) {
      if (item.menuItem.id == id) {
        match = item;
        break;
      }
    }
    if (match == null) return 0;
    bundlePrice += match.menuItem.price;
    bundles = bundles == -1
        ? match.quantity
        : (match.quantity < bundles ? match.quantity : bundles);
  }
  if (bundles <= 0) return 0;
  final discountPerBundle = bundlePrice - p.comboPrice!;
  return (discountPerBundle > 0 ? discountPerBundle : 0.0) * bundles;
}

/// Greedily applies the largest qty tier first (e.g. "6 for 180" before
/// "3 for 100"), consuming qualifying units priciest-first per group —
/// same "protect margin on the pricier units" convention as BOGO — until
/// no tier fits the remaining pool; leftover units stay at full price.
double _evaluateTiered(Promotion p, List<OrderItem> items) {
  if (p.tiered.isEmpty) return 0;
  final units = <double>[];
  for (final item in items) {
    if (!_matchesScope(p, item.menuItem)) continue;
    for (var i = 0; i < item.quantity; i++) {
      units.add(item.menuItem.price);
    }
  }
  if (units.isEmpty) return 0;
  units.sort((a, b) => b.compareTo(a));

  final tiers = [...p.tiered]
    ..sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));

  double discount = 0;
  var index = 0;
  for (final tier in tiers) {
    final qty = tier['qty'] as int;
    final price = (tier['price'] as num).toDouble();
    if (qty <= 0) continue;
    while (units.length - index >= qty) {
      final group = units.sublist(index, index + qty);
      final groupOriginal = group.fold(0.0, (s, v) => s + v);
      final saved = groupOriginal - price;
      discount += saved > 0 ? saved : 0;
      index += qty;
    }
  }
  return discount;
}
