import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'models/order.dart';
import 'order_taking_screen.dart';
import 'services/printer_service.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.order});

  final Order order;

  String _baht(double v) => '฿${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!
            .receiptAppBarTitle(order.formattedNumber)),
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
              AppLocalizations.of(context)!.businessName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)!.receiptThankYouMessage,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // Order info
            _InfoRow(AppLocalizations.of(context)!.receiptOrderLabel,
                order.formattedNumber),
            const SizedBox(height: 4),
            _InfoRow(AppLocalizations.of(context)!.receiptDateLabel,
                order.formattedDate),
            _InfoRow(
              AppLocalizations.of(context)!.receiptPaymentLabel,
              order.paymentMethod == PaymentMethod.cash
                  ? AppLocalizations.of(context)!.cash
                  : AppLocalizations.of(context)!.promptpay,
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
            _TotalRow(AppLocalizations.of(context)!.total, baht(order.total),
                bold: true),
            if (order.paymentMethod == PaymentMethod.cash) ...[
              const SizedBox(height: 4),
              _TotalRow(AppLocalizations.of(context)!.cash,
                  baht(order.amountPaid ?? 0)),
              _TotalRow(AppLocalizations.of(context)!.change,
                  baht(order.change),
                  color: AppColors.primary),
            ],
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.receiptClosingMessage,
              style: const TextStyle(
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

class _BottomActions extends StatefulWidget {
  const _BottomActions({required this.order});
  final Order order;

  @override
  State<_BottomActions> createState() => _BottomActionsState();
}

class _BottomActionsState extends State<_BottomActions> {
  final _printerService = PrinterService();
  bool _printing = false;

  Future<void> _print() async {
    setState(() => _printing = true);
    final l10n = AppLocalizations.of(context)!;
    final result = await _printerService.printReceipt(widget.order);
    if (!mounted) return;
    setState(() => _printing = false);

    final message = switch (result.outcome) {
      PrintOutcome.skipped => l10n.printSkippedMessage,
      PrintOutcome.success => l10n.printSuccessMessage,
      PrintOutcome.noPrinterFound => l10n.printNoPrinterMessage,
      PrintOutcome.failed => l10n.printFailedMessage(result.errorDetail ?? ''),
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      color: AppColors.background,
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _printing ? null : _print,
            icon: _printing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_outlined, size: 18),
            label: Text(AppLocalizations.of(context)!.printButtonLabel),
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
              child: Text(AppLocalizations.of(context)!.newOrderButton),
            ),
          ),
        ],
      ),
    );
  }
}
