import 'order_item.dart';

enum OrderStatus { open, paid, cancelled }

enum PaymentMethod { cash, promptpay }

class Order {
  Order({
    this.id,
    required this.orderNumber,
    required this.items,
    required this.createdAt,
    required this.paymentMethod,
    this.amountPaid,
    this.kitchenStatus = 'pending',
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

  /// Kitchen prep state: "pending" | "preparing" | "ready" | "completed".
  final String kitchenStatus;

  double get total => items.fold(0.0, (s, i) => s + i.subtotal);

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
  );
}
