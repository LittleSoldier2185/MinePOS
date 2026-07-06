import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'models/order.dart';
import 'order_taking_screen.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.order});

  final Order order;

  String _baht(double v) => '฿${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt ${order.formattedNumber}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _ReceiptPaper(order: order, baht: _baht),
                  ),
                ),
                _BottomActions(order: order),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptPaper extends StatelessWidget {
  const _ReceiptPaper({required this.order, required this.baht});
  final Order order;
  final String Function(double) baht;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          children: [
            // Header
            const Icon(Icons.local_cafe, color: AppColors.primary, size: 32),
            const SizedBox(height: 6),
            Text(
              'MinePOS Coffee',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Thank you for your order!',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // Order info
            _InfoRow('Order', order.formattedNumber),
            const SizedBox(height: 4),
            _InfoRow('Date', order.formattedDate),
            _InfoRow(
              'Payment',
              order.paymentMethod == PaymentMethod.cash
                  ? 'Cash'
                  : 'PromptPay',
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            // Items
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
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
                      baht(item.subtotal),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            // Totals
            _TotalRow('Total', baht(order.total), bold: true),
            if (order.paymentMethod == PaymentMethod.cash) ...[
              const SizedBox(height: 4),
              _TotalRow('Cash', baht(order.amountPaid ?? 0)),
              _TotalRow('Change', baht(order.change),
                  color: AppColors.primary),
            ],
            const SizedBox(height: 16),
            const Text(
              '— See you again! —',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value,
      {this.bold = false, this.color = AppColors.ink});
  final String label;
  final String value;
  final bool bold;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: bold ? AppColors.ink : color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style.copyWith(color: color)),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      color: AppColors.background,
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Printing — real integration coming soon.'),
                ),
              );
            },
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('PRINT'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const OrderTakingScreen()),
                  (route) => route.isFirst,
                );
              },
              child: const Text('NEW ORDER'),
            ),
          ),
        ],
      ),
    );
  }
}
