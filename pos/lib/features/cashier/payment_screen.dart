import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/app_text_field.dart';
import '../../l10n/app_localizations.dart';
import '../customer_display/services/customer_display_service.dart';
import '../manager/services/promotion_admin_service.dart';
import '../manager/services/shop_config_service.dart';
import 'models/order.dart';
import 'models/order_item.dart';
import 'receipt_screen.dart';
import 'services/order_service.dart';
import 'services/promotion_service.dart';
import 'services/promptpay_qr.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.items,
    this.note,
    this.skipPrint = false,
  });

  final List<OrderItem> items;

  /// Cashier's free-text special instructions for the kitchen — carried
  /// through to [OrderService.complete] unchanged; never shown on this
  /// screen or the receipt.
  final String? note;

  /// Ticked on the order screen — the receipt is *not* auto-printed for this
  /// sale. There's no manual print button anymore, so this is the only way to
  /// not print.
  final bool skipPrint;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _method = PaymentMethod.cash;
  final _cashController = TextEditingController();
  bool _processing = false;

  List<Promotion> _promotions = [];
  PromotionEvaluation? _evaluation;
  final _codeController = TextEditingController();
  String? _codeError;
  final Set<String> _approvedPromotionIds = {};
  final Map<String, int> _approvedByUserId = {};
  bool _approving = false;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      final promotions = await PromotionAdminService.instance.list();
      if (!mounted) return;
      setState(() => _promotions = promotions);
      _reevaluate();
    } catch (_) {
      // No promotions loaded just means checkout proceeds at plain
      // subtotal — same as before this feature existed.
    }
  }

  void _reevaluate() {
    final code = _codeController.text.trim();
    setState(() {
      _evaluation = PromotionService.evaluate(
        items: widget.items,
        promotions: _promotions,
        enteredCode: code.isEmpty ? null : code,
        approvedPromotionIds: _approvedPromotionIds,
      );
    });
    // Keeps the customer display's banner in sync the moment a discount
    // becomes known/changes — not just when the cashier happens to tap the
    // payment-method toggle (see `_onMethodChanged`, which republishes for
    // the same reason on an explicit method switch).
    if (_method == PaymentMethod.cash) {
      final applied = _evaluation?.applied ?? const <AppliedPromotion>[];
      final nextNum = OrderService.instance.nextOrderNumber.toString().padLeft(3, '0');
      CustomerDisplayService.instance.publishCart(
        items: widget.items,
        total: _total,
        orderNumber: nextNum,
        discountTotal: applied.fold(0.0, (s, a) => s + a.discountAmount),
        promotionNames: applied.map((a) => a.promotion.name).toList(),
      );
    }
  }

  void _applyCode() {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    final matches = _promotions.any((p) =>
        p.type == 'code' && p.active && p.codes.any((c) => c.code.toUpperCase() == code.toUpperCase()));
    setState(() => _codeError = matches ? null : AppLocalizations.of(context)!.invalidDiscountCodeError);
    _reevaluate();
  }

  Future<void> _openApprovalSheet(AppliedPromotion pending) async {
    final l10n = AppLocalizations.of(context)!;
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String? error;

    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.managerApprovalDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.managerApprovalDialogContent, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              AppTextField(label: l10n.usernameOrEmailLabel, controller: usernameController),
              const SizedBox(height: 12),
              AppTextField(label: l10n.passwordLabel, controller: passwordController, obscureText: true),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: AppColors.terracottaDark, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.cancel)),
            TextButton(
              onPressed: _approving
                  ? null
                  : () async {
                      setDialogState(() => _approving = true);
                      try {
                        final result = await PromotionAdminService.instance.approve(
                          username: usernameController.text,
                          password: passwordController.text,
                        );
                        _approvedPromotionIds.add(pending.promotion.id);
                        _approvedByUserId[pending.promotion.id] = result.userId;
                        if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                      } catch (e) {
                        setDialogState(() {
                          _approving = false;
                          error = '$e';
                        });
                      }
                    },
              child: Text(l10n.approveButton),
            ),
          ],
        ),
      ),
    );
    _approving = false;
    usernameController.dispose();
    passwordController.dispose();
    if (approved == true) _reevaluate();
  }

  double get _total =>
      widget.items.fold(0.0, (s, i) => s + i.subtotal) - (_evaluation?.totalDiscount ?? 0);

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

  // Mirrors the chosen payment method onto the Customer Display: PromptPay
  // shows the QR there (so the customer scans their own screen instead of
  // the cashier's), switching back to Cash restores the plain itemized cart
  // view it already had before checkout.
  void _onMethodChanged(PaymentMethod m) {
    setState(() => _method = m);
    final nextNum = OrderService.instance.nextOrderNumber.toString().padLeft(3, '0');
    if (m == PaymentMethod.promptpay) {
      final promptPayId = ShopConfigService.instance.promptPayId;
      if (promptPayId != null && promptPayId.isNotEmpty) {
        CustomerDisplayService.instance.publishPromptPay(
          payload: PromptPayQr.generatePayload(promptPayId, amount: _total),
          total: _total,
          orderNumber: nextNum,
          label: ShopConfigService.instance.promptPayLabel ?? '',
        );
      }
    } else {
      final applied = _evaluation?.applied ?? const <AppliedPromotion>[];
      CustomerDisplayService.instance.publishCart(
        items: widget.items,
        total: _total,
        orderNumber: nextNum,
        discountTotal: applied.fold(0.0, (s, a) => s + a.discountAmount),
        promotionNames: applied.map((a) => a.promotion.name).toList(),
      );
    }
  }

  Future<void> _confirm() async {
    setState(() => _processing = true);

    // Show the received cash/change on the customer-facing display the
    // moment the cashier confirms, rather than waiting on the order's round
    // trip to the server below — the amount paid and change owed are
    // already fully known locally at this point.
    CustomerDisplayService.instance.publishThankYou(total: _total, change: _change);

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    final applied = _evaluation?.applied ?? const <AppliedPromotion>[];
    final bogoByItemId = PromotionService.bogoDiscountByItemId(widget.items, _promotions);
    final itemsWithDiscount =
        widget.items.map((i) => i.copy(discountAmount: bogoByItemId[i.menuItem.id] ?? 0)).toList();

    final order = await OrderService.instance.complete(
      items: itemsWithDiscount,
      paymentMethod: _method,
      amountPaid: _method == PaymentMethod.cash ? _amountPaid : null,
      appliedPromotions: applied,
      approvedByUserId: _approvedByUserId,
      note: widget.note,
    );

    if (!mounted) return;
    // `result: true` travels back to OrderTakingScreen's awaited push() — its
    // signal that the sale went through and its cart must not be re-held.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(order: order, autoPrint: !widget.skipPrint),
      ),
      result: true,
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.paymentAppBarTitle),
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
                            items: widget.items, baht: baht, evaluation: _evaluation),
                        if (_promotions.any((p) => p.type == 'code')) ...[
                          const SizedBox(height: 12),
                          _DiscountCodeField(
                            controller: _codeController,
                            error: _codeError,
                            onApply: _applyCode,
                          ),
                        ],
                        if ((_evaluation?.pendingApproval ?? const []).isNotEmpty) ...[
                          const SizedBox(height: 12),
                          for (final pending in _evaluation!.pendingApproval)
                            _PendingApprovalRow(
                              pending: pending,
                              baht: baht,
                              onApprove: () => _openApprovalSheet(pending),
                            ),
                        ],
                        const SizedBox(height: 20),
                        _PaymentMethodToggle(
                          selected: _method,
                          onChanged: _onMethodChanged,
                        ),
                        const SizedBox(height: 20),
                        if (_method == PaymentMethod.cash)
                          _CashPanel(
                            total: _total,
                            change: _change,
                            controller: _cashController,
                            baht: baht,
                            onChanged: (_) => setState(() {}),
                          )
                        else
                          _PromptPayPanel(total: _total, baht: baht),
                      ],
                    ),
                  ),
                ),
                _ConfirmBar(
                  total: _total,
                  canConfirm: _canConfirm,
                  processing: _processing,
                  baht: baht,
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
  const _OrderSummaryCard({required this.items, required this.baht, this.evaluation});
  final List<OrderItem> items;
  final String Function(double) baht;
  final PromotionEvaluation? evaluation;

  String _itemLabel(BuildContext context, OrderItem item) {
    final name = item.menuItem.displayName(Localizations.localeOf(context));
    if (item.sweetness == null) return name;
    return '$name (${item.sweetness!.label(AppLocalizations.of(context)!)})';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtotal = items.fold(0.0, (s, i) => s + i.subtotal);
    final applied = evaluation?.applied ?? const <AppliedPromotion>[];
    final total = subtotal - applied.fold(0.0, (s, a) => s + a.discountAmount);
    // A Subtotal breakdown only earns its keep once there's actually a
    // discount to explain — otherwise it's just the same number twice.
    final hasDiscount = applied.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.orderSummaryHeader,
              style: const TextStyle(
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
                        child: Text(_itemLabel(context, item),
                            style: const TextStyle(fontSize: 13))),
                    Text(baht(item.subtotal),
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            if (hasDiscount) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.subtotalLabel, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                  Text(baht(subtotal), style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                ],
              ),
              for (final a in applied)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(a.promotion.name,
                            style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                      ),
                      Text('-${baht(a.discountAmount)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                    ],
                  ),
                ),
              const Divider(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.total,
                    style: const TextStyle(
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

class _DiscountCodeField extends StatelessWidget {
  const _DiscountCodeField({required this.controller, required this.error, required this.onApply});
  final TextEditingController controller;
  final String? error;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                label: l10n.discountCodeFieldLabel,
                hintText: l10n.discountCodeFieldHint,
                controller: controller,
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: OutlinedButton(onPressed: onApply, child: Text(l10n.applyCodeButton)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingApprovalRow extends StatelessWidget {
  const _PendingApprovalRow({required this.pending, required this.baht, required this.onApprove});
  final AppliedPromotion pending;
  final String Function(double) baht;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: AppColors.terracottaLight.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${l10n.promotionNeedsApprovalLabel(pending.promotion.name)} (-${baht(pending.discountAmount)})',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            TextButton(onPressed: onApprove, child: Text(l10n.approveButton)),
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
          label: AppLocalizations.of(context)!.cash,
          icon: Icons.payments_outlined,
          active: selected == PaymentMethod.cash,
          onTap: () => onChanged(PaymentMethod.cash),
        ),
        const SizedBox(width: 12),
        _MethodButton(
          label: AppLocalizations.of(context)!.promptpay,
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
            Text(
              AppLocalizations.of(context)!.amountReceivedHeader,
              style: const TextStyle(
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
                errorText: insufficient
                    ? AppLocalizations.of(context)!.amountLessThanTotalError
                    : null,
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
                  Text(AppLocalizations.of(context)!.change,
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.muted)),
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

  bool get _hasLabel {
    final label = ShopConfigService.instance.promptPayLabel;
    return label != null && label.isNotEmpty;
  }

  void _showEnlarged(BuildContext context, String promptPayId) {
    final size = (MediaQuery.sizeOf(context).width * 0.8).clamp(240.0, 420.0);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/promptpay_logo.png', height: 34),
              const SizedBox(height: 16),
              QrImageView(
                data: PromptPayQr.generatePayload(promptPayId, amount: total),
                size: size,
              ),
              if (_hasLabel) ...[
                const SizedBox(height: 12),
                Text(
                  ShopConfigService.instance.promptPayLabel!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                baht(total),
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final promptPayId = ShopConfigService.instance.promptPayId;
    final configured = promptPayId != null && promptPayId.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (configured) ...[
              Image.asset('assets/images/promptpay_logo.png', height: 26),
              const SizedBox(height: 12),
            ],
            GestureDetector(
              onTap: configured ? () => _showEnlarged(context, promptPayId) : null,
              child: Container(
                width: 180,
                height: 180,
                padding: EdgeInsets.all(configured ? 12 : 0),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: configured
                    ? QrImageView(
                        data: PromptPayQr.generatePayload(promptPayId, amount: total),
                        backgroundColor: Colors.white,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2,
                              size: 80,
                              color: AppColors.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.promptpayConfigMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.muted),
                          ),
                        ],
                      ),
              ),
            ),
            if (configured) ...[
              if (_hasLabel) ...[
                const SizedBox(height: 8),
                Text(
                  ShopConfigService.instance.promptPayLabel!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.tapToEnlargeQrMessage,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              baht(total),
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.scanQrToPayMessage,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
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
              : Text(
                  AppLocalizations.of(context)!.confirmPaymentButton(
                      baht(total)),
                ),
        ),
      ),
    );
  }
}
