import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/cashier/models/menu_item.dart';
import 'package:pos/features/cashier/models/order_item.dart';
import 'package:pos/features/cashier/services/promotion_service.dart';
import 'package:pos/features/manager/services/promotion_admin_service.dart';

MenuItem _item(String id, String category, double price) =>
    MenuItem(id: id, name: id, category: category, price: price);

OrderItem _line(MenuItem item, int qty) => OrderItem(menuItem: item, quantity: qty);

Promotion _promo({
  required String id,
  required String type,
  String scopeType = 'shop',
  List<String> scopeItemIds = const [],
  String? scopeCategory,
  List<String>? scopeCategories,
  List<String> excludeItemIds = const [],
  double? percentValue,
  double? flatAmount,
  double? maxDiscountCap,
  double? minSpendAmount,
  int? bogoBuyQty,
  int? bogoGetQty,
  double? bogoGetDiscountPercent,
  double? comboPrice,
  List<Map<String, dynamic>> tiered = const [],
  DateTime? startDate,
  DateTime? endDate,
  List<int>? daysOfWeek,
  String? timeStart,
  String? timeEnd,
  bool requiresManagerApproval = false,
  double? approvalThresholdAmount,
  List<PromotionCode> codes = const [],
}) =>
    Promotion(
      id: id,
      name: id,
      type: type,
      active: true,
      scopeType: scopeType,
      scopeItemIds: scopeItemIds,
      scopeCategories: scopeCategories ?? (scopeCategory == null ? const [] : [scopeCategory]),
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
      codes: codes,
    );

void main() {
  final latte = _item('latte', 'Drink', 100);
  final croissant = _item('croissant', 'Pastry', 60);
  final muffin = _item('muffin', 'Pastry', 40);

  test('percent: shop-wide discount applies to whole subtotal', () {
    final result = PromotionService.evaluate(
      items: [_line(latte, 1)],
      promotions: [_promo(id: 'p1', type: 'percent', percentValue: 10)],
    );
    expect(result.totalDiscount, 10);
  });

  test('percent: clamped to maxDiscountCap when the raw percentage exceeds it', () {
    final result = PromotionService.evaluate(
      items: [_line(latte, 5)], // subtotal 500, 20% = 100
      promotions: [_promo(id: 'p1', type: 'percent', percentValue: 20, maxDiscountCap: 30)],
    );
    expect(result.totalDiscount, 30);
  });

  test('category scope with multiple categories matches items in any of them', () {
    final result = PromotionService.evaluate(
      items: [_line(latte, 1), _line(croissant, 1), _line(muffin, 1)],
      promotions: [
        _promo(
          id: 'p1',
          type: 'percent',
          scopeType: 'category',
          scopeCategories: ['Drink', 'Pastry'],
          percentValue: 10,
        ),
      ],
    );
    // Every item here is Drink or Pastry, so the full subtotal (100+60+40=200) qualifies.
    expect(result.totalDiscount, 20);
  });

  test('category scope excludes items outside every listed category', () {
    final bagel = _item('bagel', 'Bakery', 50);
    final result = PromotionService.evaluate(
      items: [_line(latte, 1), _line(bagel, 1)],
      promotions: [
        _promo(
          id: 'p1',
          type: 'percent',
          scopeType: 'category',
          scopeCategories: ['Drink', 'Pastry'],
          percentValue: 10,
        ),
      ],
    );
    // Only the latte (Drink) counts — bagel is Bakery, not in scopeCategories.
    expect(result.totalDiscount, 10);
  });

  test('flat: never discounts below the matching subtotal', () {
    final result = PromotionService.evaluate(
      items: [_line(muffin, 1)], // subtotal 40
      promotions: [_promo(id: 'p1', type: 'flat', flatAmount: 100)],
    );
    expect(result.totalDiscount, 40);
  });

  test('bogo: buy 2 get 1 free makes the cheapest of every complete group of 3 free', () {
    // 3 croissants (60 each) qualify as one complete group of 3 (buy 2 get
    // 1) — priciest-first sort means all three are equal price here, so the
    // "cheapest" one discounted is still 60.
    final result = PromotionService.evaluate(
      items: [_line(croissant, 3)],
      promotions: [
        _promo(id: 'p1', type: 'bogo', scopeType: 'category', scopeCategory: 'Pastry', bogoBuyQty: 2, bogoGetQty: 1, bogoGetDiscountPercent: 100),
      ],
    );
    expect(result.totalDiscount, 60);
  });

  test('bogo: a trailing partial group gets no discount', () {
    // 4 units, group size 3 -> one complete group discounted, 1 leftover untouched.
    final result = PromotionService.evaluate(
      items: [_line(croissant, 4)],
      promotions: [
        _promo(id: 'p1', type: 'bogo', scopeType: 'category', scopeCategory: 'Pastry', bogoBuyQty: 2, bogoGetQty: 1, bogoGetDiscountPercent: 100),
      ],
    );
    expect(result.totalDiscount, 60);
  });

  test('combo: bundle price applies once per the scarcest required item\'s quantity', () {
    // 2 lattes + 2 croissants -> bundlePrice 160 each, combo 120 -> 2 bundles, 40 saved each = 80.
    final result = PromotionService.evaluate(
      items: [_line(latte, 2), _line(croissant, 2)],
      promotions: [
        _promo(id: 'p1', type: 'combo', scopeItemIds: ['latte', 'croissant'], comboPrice: 120),
      ],
    );
    expect(result.totalDiscount, 80);
  });

  test('combo: missing a required item entirely means zero bundles', () {
    final result = PromotionService.evaluate(
      items: [_line(latte, 2)],
      promotions: [
        _promo(id: 'p1', type: 'combo', scopeItemIds: ['latte', 'croissant'], comboPrice: 120),
      ],
    );
    expect(result.totalDiscount, 0);
  });

  test('tiered: "3 for 100" applies to one complete group, leftovers stay full price', () {
    // 5 croissants at 60 each (300 total). One group of 3 -> tier price 100
    // (saves 80). 2 leftover units at full price (no further tier fits).
    final result = PromotionService.evaluate(
      items: [_line(croissant, 5)],
      promotions: [
        _promo(
          id: 'p1',
          type: 'tiered',
          scopeType: 'category',
          scopeCategory: 'Pastry',
          tiered: [
            {'qty': 3, 'price': 100},
          ],
        ),
      ],
    );
    expect(result.totalDiscount, 80);
  });

  test('min_spend: reward only applies once the threshold is met', () {
    final belowThreshold = PromotionService.evaluate(
      items: [_line(latte, 1)], // 100
      promotions: [_promo(id: 'p1', type: 'min_spend', minSpendAmount: 150, percentValue: 10)],
    );
    expect(belowThreshold.totalDiscount, 0);

    final aboveThreshold = PromotionService.evaluate(
      items: [_line(latte, 2)], // 200
      promotions: [_promo(id: 'p1', type: 'min_spend', minSpendAmount: 150, percentValue: 10)],
    );
    expect(aboveThreshold.totalDiscount, 20);
  });

  test('code: applies only with the matching code, case-insensitively, and rejects a used-up code', () {
    final promo = _promo(
      id: 'p1',
      type: 'code',
      flatAmount: 20,
      codes: [PromotionCode(id: 'c1', promotionId: 'p1', code: 'SAVE20', maxUses: 1, usedCount: 0)],
    );

    final noCode = PromotionService.evaluate(items: [_line(latte, 1)], promotions: [promo]);
    expect(noCode.totalDiscount, 0);

    final wrongCode =
        PromotionService.evaluate(items: [_line(latte, 1)], promotions: [promo], enteredCode: 'WRONG');
    expect(wrongCode.totalDiscount, 0);

    final rightCode =
        PromotionService.evaluate(items: [_line(latte, 1)], promotions: [promo], enteredCode: 'save20');
    expect(rightCode.totalDiscount, 20);

    final usedUpPromo = _promo(
      id: 'p1',
      type: 'code',
      flatAmount: 20,
      codes: [PromotionCode(id: 'c1', promotionId: 'p1', code: 'SAVE20', maxUses: 1, usedCount: 1)],
    );
    final usedUp =
        PromotionService.evaluate(items: [_line(latte, 1)], promotions: [usedUpPromo], enteredCode: 'SAVE20');
    expect(usedUp.totalDiscount, 0);
  });

  test('schedule: a promotion outside its day-of-week window does not apply', () {
    // Derived from `today` itself (never a hardcoded "this date is a
    // Monday" assumption) so the test can't silently rot if the reference
    // date's actual weekday isn't what a comment claims.
    final today = DateTime(2026, 7, 27);
    final todayIndex = today.weekday - 1;
    final otherDayIndex = (todayIndex + 1) % 7;

    final onlyOtherDay = _promo(id: 'p1', type: 'flat', flatAmount: 10, daysOfWeek: [otherDayIndex]);
    final result = PromotionService.evaluate(items: [_line(latte, 1)], promotions: [onlyOtherDay], now: today);
    expect(result.totalDiscount, 0);

    final onlyToday = _promo(id: 'p1', type: 'flat', flatAmount: 10, daysOfWeek: [todayIndex]);
    final result2 = PromotionService.evaluate(items: [_line(latte, 1)], promotions: [onlyToday], now: today);
    expect(result2.totalDiscount, 10);
  });

  test('schedule: a promotion outside its date range does not apply', () {
    final now = DateTime(2026, 7, 27);
    final expired = _promo(
      id: 'p1',
      type: 'flat',
      flatAmount: 10,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 31),
    );
    final result = PromotionService.evaluate(items: [_line(latte, 1)], promotions: [expired], now: now);
    expect(result.totalDiscount, 0);
  });

  test('stacking: BOGO and percent both apply, percent does not double-count the BOGO\'d amount', () {
    // 3 croissants (60 each, 180 total): BOGO takes one free (60), leaving
    // 120 of "real" value; percent (10%) should apply to that net 120, not
    // the original 180.
    final result = PromotionService.evaluate(
      items: [_line(croissant, 3)],
      promotions: [
        _promo(id: 'bogo', type: 'bogo', scopeType: 'category', scopeCategory: 'Pastry', bogoBuyQty: 2, bogoGetQty: 1, bogoGetDiscountPercent: 100),
        _promo(id: 'pct', type: 'percent', scopeType: 'category', scopeCategory: 'Pastry', percentValue: 10),
      ],
    );
    // 60 (bogo) + 12 (10% of remaining 120) = 72
    expect(result.totalDiscount, 72);
    expect(result.applied.length, 2);
  });

  test('manager approval: an over-threshold discount is withheld until approved', () {
    final promo = _promo(
      id: 'p1',
      type: 'flat',
      flatAmount: 50,
      requiresManagerApproval: true,
      approvalThresholdAmount: 20,
    );
    final unapproved = PromotionService.evaluate(items: [_line(latte, 1)], promotions: [promo]);
    expect(unapproved.totalDiscount, 0);
    expect(unapproved.pendingApproval.length, 1);
    expect(unapproved.applied, isEmpty);

    final approved = PromotionService.evaluate(
      items: [_line(latte, 1)],
      promotions: [promo],
      approvedPromotionIds: {'p1'},
    );
    expect(approved.totalDiscount, 50);
    expect(approved.pendingApproval, isEmpty);
  });

  test('manager approval: below the threshold does not require approval at all', () {
    final promo = _promo(
      id: 'p1',
      type: 'flat',
      flatAmount: 5,
      requiresManagerApproval: true,
      approvalThresholdAmount: 20,
    );
    final result = PromotionService.evaluate(items: [_line(latte, 1)], promotions: [promo]);
    expect(result.totalDiscount, 5);
    expect(result.pendingApproval, isEmpty);
  });
}
