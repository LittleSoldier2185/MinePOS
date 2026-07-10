import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'models/order.dart';
import 'services/order_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Order> get _orders => OrderService.instance.orders;

  String _baht(double v) => '฿${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.orderHistoryAppBarTitle),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _orders.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 56, color: AppColors.muted.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.noOrdersMessage,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _orders.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final order = _orders[index];
                return _OrderTile(order: order, baht: _baht);
              },
            ),
    );
  }
}

class _OrderTile extends StatefulWidget {
  const _OrderTile({required this.order, required this.baht});
  final Order order;
  final String Function(double) baht;

  @override
  State<_OrderTile> createState() => _OrderTileState();
}

class _OrderTileState extends State<_OrderTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final methodLabel = o.paymentMethod == PaymentMethod.cash
        ? AppLocalizations.of(context)!.cash
        : AppLocalizations.of(context)!.promptpay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          onTap: () => setState(() => _expanded = !_expanded),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                o.formattedNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          title: Text(
            AppLocalizations.of(context)!
                .orderItemsSummary(o.items.length, methodLabel),
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            o.formattedDate,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.baht(o.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.muted,
                size: 20,
              ),
            ],
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...o.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          '${item.quantity}×',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item.menuItem.name,
                              style: const TextStyle(fontSize: 13)),
                        ),
                        Text(
                          widget.baht(item.subtotal),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                if (o.paymentMethod == PaymentMethod.cash) ...[
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.cash,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted)),
                      Text(widget.baht(o.amountPaid ?? 0),
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.change,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted)),
                      Text(widget.baht(o.change),
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
