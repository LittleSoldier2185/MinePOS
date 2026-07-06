import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import 'models/order.dart';
import 'models/order_item.dart';
import 'receipt_screen.dart';
import 'services/order_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.items});

  final List<OrderItem> items;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _method = PaymentMethod.cash;
  final _cashController = TextEditingController();
  bool _processing = false;

  double get _total =>
      widget.items.fold(0.0, (s, i) => s + i.subtotal);

  double? get _amountPaid {
    final v = double.tryParse(_cashController.text);
    if (v == null || v <= 0) return null;
    return v;
  }

  double get _change {
    final paid = _amountPaid;
    if (paid == null) return 0;
    return paid - _total;
  }

  bool get _canConfirm {
    if (_method == PaymentMethod.promptpay) return true;
    final paid = _amountPaid;
    return paid != null && paid >= _total;
  }

  String _baht(double v) => '฿${v.toStringAsFixed(0)}';

  Future<void> _confirm() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    final order = await OrderService.instance.complete(
      items: widget.items,
      paymentMethod: _method,
      amountPaid: _method == PaymentMethod.cash ? _amountPaid : null,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ReceiptScreen(order: order)),
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _OrderSummaryCard(
                            items: widget.items, baht: _baht),
                        const SizedBox(height: 20),
                        _PaymentMethodToggle(
                          selected: _method,
                          onChanged: (m) =>
                              setState(() => _method = m),
                        ),
                        const SizedBox(height: 20),
                        if (_method == PaymentMethod.cash)
                          _CashPanel(
                            total: _total,
                            change: _change,
                            controller: _cashController,
                            baht: _baht,
                            onChanged: (_) => setState(() {}),
                          )
                        else
                          _PromptPayPanel(total: _total, baht: _baht),
                      ],
                    ),
                  ),
                ),
                _ConfirmBar(
                  total: _total,
                  canConfirm: _canConfirm,
                  processing: _processing,
                  baht: _baht,
                  onConfirm: _confirm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Order summary ────────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.items, required this.baht});
  final List<OrderItem> items;
  final String Function(double) baht;

  @override
  Widget build(BuildContext context) {
    final total = items.fold(0.0, (s, i) => s + i.subtotal);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ORDER SUMMARY',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text('${item.quantity}×',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(item.menuItem.name,
                            style: const TextStyle(fontSize: 13))),
                    Text(baht(item.subtotal),
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(baht(total),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment method toggle ────────────────────────────────────────────────────

class _PaymentMethodToggle extends StatelessWidget {
  const _PaymentMethodToggle(
      {required this.selected, required this.onChanged});
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MethodButton(
          label: 'Cash',
          icon: Icons.payments_outlined,
          active: selected == PaymentMethod.cash,
          onTap: () => onChanged(PaymentMethod.cash),
        ),
        const SizedBox(width: 12),
        _MethodButton(
          label: 'PromptPay',
          icon: Icons.qr_code,
          active: selected == PaymentMethod.promptpay,
          onTap: () => onChanged(PaymentMethod.promptpay),
        ),
      ],
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.terracottaLight,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: active ? AppColors.accent : AppColors.muted,
                  size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.accent : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cash panel ───────────────────────────────────────────────────────────────

class _CashPanel extends StatelessWidget {
  const _CashPanel({
    required this.total,
    required this.change,
    required this.controller,
    required this.baht,
    required this.onChanged,
  });
  final double total;
  final double change;
  final TextEditingController controller;
  final String Function(double) baht;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final paid = double.tryParse(controller.text) ?? 0;
    final insufficient = paid > 0 && paid < total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AMOUNT RECEIVED',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: onChanged,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                prefixText: '฿',
                prefixStyle: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.muted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.terracottaLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                errorText: insufficient ? 'Amount is less than total' : null,
              ),
            ),
            const SizedBox(height: 16),
            // Quick-fill buttons
            Row(
              children: [
                for (final amount in _quickAmounts(total))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                        onPressed: () {
                          controller.text = amount.toStringAsFixed(0);
                          onChanged(controller.text);
                        },
                        child: Text(baht(amount)),
                      ),
                    ),
                  ),
              ],
            ),
            if (paid >= total && paid > 0) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Change',
                      style: TextStyle(fontSize: 15, color: AppColors.muted)),
                  Text(
                    baht(change),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static List<double> _quickAmounts(double total) {
    final rounded = (total / 50).ceil() * 50.0;
    return [total, rounded, rounded + 50, rounded + 100]
        .where((v) => v >= total)
        .take(4)
        .toList();
  }
}

// ── PromptPay panel ──────────────────────────────────────────────────────────

class _PromptPayPanel extends StatelessWidget {
  const _PromptPayPanel({required this.total, required this.baht});
  final double total;
  final String Function(double) baht;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2,
                      size: 80,
                      color: AppColors.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 4),
                  const Text(
                    'Configure PromptPay ID\nin Settings to enable',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              baht(total),
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            const Text(
              'Scan QR to pay',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Confirm bar ──────────────────────────────────────────────────────────────

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.total,
    required this.canConfirm,
    required this.processing,
    required this.baht,
    required this.onConfirm,
  });
  final double total;
  final bool canConfirm;
  final bool processing;
  final String Function(double) baht;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      color: AppColors.background,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (!canConfirm || processing) ? null : onConfirm,
          child: processing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accent),
                )
              : Text('CONFIRM PAYMENT  •  ${baht(total)}'),
        ),
      ),
    );
  }
}
