import 'order_item.dart';

enum OrderStatus { open, paid, cancelled }

enum PaymentMethod { cash, promptpay }

/// One promotion that applied to an order, as recorded server-side in
/// `order_promotions` — audit trail + what the receipt shows, joined with
/// the promotion's own name so a display doesn't need a separate lookup
/// (mirrors `DbAppliedPromotion` server-side).
class AppliedOrderPromotion {
  AppliedOrderPromotion({
    required this.promotionId,
    required this.name,
    required this.discountAmount,
    this.codeUsed,
  });

  final String promotionId;
  final String name;
  final double discountAmount;
  final String? codeUsed;

  factory AppliedOrderPromotion.fromJson(Map<String, dynamic> json) => AppliedOrderPromotion(
        promotionId: json['promotionId'] as String,
        name: json['name'] as String,
        discountAmount: (json['discountAmount'] as num).toDouble(),
        codeUsed: json['codeUsed'] as String?,
      );
}

class Order {
  Order({
    this.id,
    required this.orderNumber,
    required this.items,
    required this.createdAt,
    required this.paymentMethod,
    this.amountPaid,
    this.kitchenStatus = 'pending',
    this.cancelReason,
    this.discountTotal = 0,
    this.appliedPromotions = const [],
    this.createdByUserId,
    this.createdByName,
  }) : status = OrderStatus.paid;

  /// Server-assigned primary key — null until synced (used for kitchen
  /// status updates; distinct from [orderNumber], the shop-facing counter).
  final int? id;
  final int orderNumber;
  final List<OrderItem> items;
  final DateTime createdAt;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final double? amountPaid;

  /// Kitchen prep state: "pending" | "preparing" | "ready" | "completed" | "cancelled".
  final String kitchenStatus;

  /// Set only when [kitchenStatus] is "cancelled" — the reason chosen (plus
  /// any free-text detail) at cancel time.
  final String? cancelReason;

  /// Sum of every applied promotion's discount — see [appliedPromotions]
  /// for the per-promotion breakdown the receipt actually renders.
  final double discountTotal;
  final List<AppliedOrderPromotion> appliedPromotions;

  /// Which staff member rang this up — null for orders placed before this
  /// existed, or (rarely) one placed fully offline where the server never
  /// got a chance to assign it. [createdByName] is what Reports groups by.
  final int? createdByUserId;
  final String? createdByName;

  /// Cancelling is only safe while no item has started prep — once the
  /// order moves off "pending" (server-derived from item statuses), the
  /// kitchen may already be acting on it.
  bool get canCancel => kitchenStatus == 'pending';

  double get subtotal => items.fold(0.0, (s, i) => s + i.subtotal);

  /// Net of [discountTotal] — this is what the customer actually owes, same
  /// number the cashier confirmed payment against.
  double get total => subtotal - discountTotal;

  double get change => paymentMethod == PaymentMethod.cash && amountPaid != null
      ? amountPaid! - total
      : 0.0;

  String get formattedNumber => '#${orderNumber.toString().padLeft(3, '0')}';

  String get formattedDate {
    final d = createdAt;
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '$date $formattedTime';
  }

  String get formattedTime {
    final d = createdAt;
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as int?,
    orderNumber: json['orderNumber'] as int,
    items: (json['items'] as List)
        .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    paymentMethod: (json['paymentMethod'] as String) == 'promptpay'
        ? PaymentMethod.promptpay
        : PaymentMethod.cash,
    amountPaid: (json['amountPaid'] as num?)?.toDouble(),
    kitchenStatus: json['status'] as String? ?? 'pending',
    cancelReason: json['cancelReason'] as String?,
    discountTotal: (json['discountTotal'] as num?)?.toDouble() ?? 0,
    appliedPromotions: (json['appliedPromotions'] as List?)
            ?.map((j) => AppliedOrderPromotion.fromJson(j as Map<String, dynamic>))
            .toList() ??
        const [],
    createdByUserId: json['createdByUserId'] as int?,
    createdByName: json['createdByName'] as String?,
  );
}
