import '../../../l10n/app_localizations.dart';
import 'menu_item.dart';

/// Less/Normal/Sweet — the only levels a cashier can pick, for a drink item
/// flagged with [MenuItem.hasSweetness]. Null on the item means "no
/// sweetness choice applies" (a food item, or sweetness wasn't asked).
enum SweetnessLevel { less, normal, sweet }

extension SweetnessLevelLabel on SweetnessLevel {
  String label(AppLocalizations l10n) => switch (this) {
        SweetnessLevel.less => l10n.sweetnessLess,
        SweetnessLevel.normal => l10n.sweetnessNormal,
        SweetnessLevel.sweet => l10n.sweetnessSweet,
      };
}

class OrderItem {
  OrderItem({
    required this.menuItem,
    this.quantity = 1,
    this.id,
    this.status = 'pending',
    this.sweetness,
  });

  final MenuItem menuItem;
  int quantity;

  /// Server-assigned row id — null for cart items that haven't been sent to
  /// the server yet (only meaningful once an order exists, for the Kitchen
  /// Display's per-item status route).
  final int? id;

  /// Kitchen prep state: "pending" | "preparing" | "ready". Only meaningful
  /// on items pulled from the Kitchen Display's live orders — cart items
  /// never set or read this.
  final String status;

  /// Chosen sweetness level, only set when [menuItem.hasSweetness].
  final SweetnessLevel? sweetness;

  double get subtotal => menuItem.price * quantity;

  OrderItem copy() => OrderItem(
        menuItem: menuItem,
        quantity: quantity,
        id: id,
        status: status,
        sweetness: sweetness,
      );

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as int?,
        menuItem: MenuItem(
          id: json['menuItemId'] as String,
          name: json['menuItemName'] as String,
          category: json['menuItemCategory'] as String,
          price: (json['price'] as num).toDouble(),
          nameTh: json['menuItemNameTh'] as String?,
        ),
        quantity: json['quantity'] as int,
        status: json['status'] as String? ?? 'pending',
        sweetness: (json['sweetness'] as String?) == null
            ? null
            : SweetnessLevel.values.byName(json['sweetness'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'menuItemId': menuItem.id,
        'menuItemName': menuItem.name,
        'menuItemNameTh': menuItem.nameTh,
        'menuItemCategory': menuItem.category,
        'price': menuItem.price,
        'quantity': quantity,
        'status': status,
        'sweetness': sweetness?.name,
      };
}
