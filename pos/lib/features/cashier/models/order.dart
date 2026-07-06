import 'order_item.dart';

enum OrderStatus { open, paid, cancelled }

enum PaymentMethod { cash, promptpay }

class Order {
  Order({
    required this.orderNumber,
    required this.items,
    required this.createdAt,
    required this.paymentMethod,
    this.amountPaid,
  }) : status = OrderStatus.paid;

  final int orderNumber;
  final List<OrderItem> items;
  final DateTime createdAt;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final double? amountPaid;

  double get total => items.fold(0.0, (s, i) => s + i.subtotal);

  double get change =>
      paymentMethod == PaymentMethod.cash && amountPaid != null
          ? amountPaid! - total
          : 0.0;

  String get formattedNumber =>
      '#${orderNumber.toString().padLeft(3, '0')}';

  String get formattedDate {
    final d = createdAt;
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        orderNumber: json['orderNumber'] as int,
        items: (json['items'] as List)
            .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        paymentMethod: (json['paymentMethod'] as String) == 'promptpay'
            ? PaymentMethod.promptpay
            : PaymentMethod.cash,
        amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      );
}
