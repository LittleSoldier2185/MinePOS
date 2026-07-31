import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatting.dart';
import '../../l10n/app_localizations.dart';
import '../home/mobile_bottom_nav.dart';
import 'models/order.dart';
import 'models/order_item.dart';
import 'services/order_service.dart';
import 'services/printer_service.dart';
import 'widgets/cancel_order_dialog.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Order> get _orders => OrderService.instance.orders;

  @override
  void initState() {
    super.initState();
    OrderService.instance.addListener(_onOrdersChanged);
  }

  @override
  void dispose() {
    OrderService.instance.removeListener(_onOrdersChanged);
    super.dispose();
  }

  // Orders placed on another device arrive over OrderService's own
  // /ws/orders connection; this just triggers a rebuild to show them.
  void _onOrdersChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.orderHistoryAppBarTitle),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: !isMobile,
      ),
      floatingActionButton: isMobile ? const MobileNewOrderFab() : null,
      floatingActionButtonLocation: isMobile ? FloatingActionButtonLocation.centerDocked : null,
      bottomNavigationBar: isMobile ? const MobileBottomNav(current: MobileTab.orders) : null,
      body: _orders.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 56,
                    color: AppColors.muted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.noOrdersMessage,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            )
          : _buildGroupedList(context),
    );
  }

  // Orders are already newest-first, so same-day orders are always
  // contiguous — a single pass is enough to insert a header whenever the
  // calendar day changes.
  Widget _buildGroupedList(BuildContext context) {
    final dateFmt = DateFormat(
      'EEEE, d MMMM yyyy',
      Localizations.localeOf(context).toString(),
    );
    final children = <Widget>[];
    DateTime? lastDay;
    for (final order in _orders) {
      final d = order.createdAt;
      final day = DateTime(d.year, d.month, d.day);
      if (day != lastDay) {
        if (lastDay != null) children.add(const SizedBox(height: 4));
        children.add(_DateHeader(text: dateFmt.format(day)));
        lastDay = day;
      } else {
        children.add(const Divider(height: 1));
      }
      children.add(_OrderTile(order: order, baht: baht));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: children,
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
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
  final _printerService = PrinterService();
  bool _printing = false;

  String _itemLabel(BuildContext context, OrderItem item) {
    final name = item.menuItem.displayName(Localizations.localeOf(context));
    if (item.sweetness == null) return name;
    return '$name (${item.sweetness!.label(AppLocalizations.of(context)!)})';
  }

  Future<void> _reprint(Order o) async {
    setState(() => _printing = true);
    final l10n = AppLocalizations.of(context)!;
    final result = await _printerService.printReceipt(o);
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

  Future<void> _confirmCancel(Order o) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await showCancelOrderDialog(context);
    if (reason == null || !mounted) return;
    try {
      await OrderService.instance.cancelOrder(o.id!, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cancelOrderSnackbar)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.cancelOrderFailedSnackbar('$e')),
            backgroundColor: AppColors.terracottaDark),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final l10n = AppLocalizations.of(context)!;
    final methodLabel = o.paymentMethod == PaymentMethod.cash
        ? AppLocalizations.of(context)!.cash
        : AppLocalizations.of(context)!.promptpay;
    final canCancel = o.canCancel && o.id != null;
    final cancelled = o.kitchenStatus == 'cancelled';

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
            AppLocalizations.of(
              context,
            )!.orderItemsSummary(o.items.length, methodLabel),
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            o.formattedTime,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cancelled)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.terracottaLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(l10n.cancelledOrderBadge,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.terracottaDark)),
                ),
              if (canCancel)
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.terracottaDark),
                  tooltip: l10n.cancelOrderLabel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _confirmCancel(o),
                ),
              IconButton(
                icon: _printing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print_outlined, size: 18, color: AppColors.muted),
                tooltip: l10n.printButtonLabel,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: _printing ? null : () => _reprint(o),
              ),
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
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _itemLabel(context, item),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          widget.baht(item.subtotal),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                if (o.createdByName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.staffLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        o.createdByName!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
                if (o.appliedPromotions.isNotEmpty) ...[
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.subtotalLabel,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      Text(widget.baht(o.subtotal), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  for (final promo in o.appliedPromotions)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              promo.name,
                              style: const TextStyle(fontSize: 12, color: AppColors.primary),
                            ),
                          ),
                          Text(
                            '-${widget.baht(promo.discountAmount)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                if (o.kitchenStatus == 'cancelled' && o.cancelReason != null) ...[
                  const Divider(height: 16),
                  Text(
                    '${AppLocalizations.of(context)!.cancelledOrderBadge}: ${o.cancelReason}',
                    style: const TextStyle(fontSize: 12, color: AppColors.terracottaDark),
                  ),
                ],
                if (o.paymentMethod == PaymentMethod.cash) ...[
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.cash,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        widget.baht(o.amountPaid ?? 0),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.change,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        widget.baht(o.change),
                        style: const TextStyle(fontSize: 12),
                      ),
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

