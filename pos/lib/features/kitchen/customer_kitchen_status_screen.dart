import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../cashier/models/order.dart';
import 'services/kitchen_service.dart';

/// Public order-tracking board — pushed from [KitchenDisplayScreen] for a
/// screen customers can see (a second monitor, a tablet on the counter).
/// Deliberately shows only each order's number and which stage it's at:
/// no items, no cashier notes/special instructions, no tap actions. Reads
/// the same shared [KitchenService] connection the barista screen underneath
/// already opened — this screen only adds a listener, it never connects or
/// disconnects that shared socket itself.
class CustomerKitchenStatusScreen extends StatefulWidget {
  const CustomerKitchenStatusScreen({super.key});

  @override
  State<CustomerKitchenStatusScreen> createState() =>
      _CustomerKitchenStatusScreenState();
}

class _CustomerKitchenStatusScreenState
    extends State<CustomerKitchenStatusScreen> {
  final _svc = KitchenService.instance;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onChange);
    _svc.connect();
  }

  @override
  void dispose() {
    _svc.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pending = _svc.orders
        .where((o) => o.kitchenStatus == 'pending')
        .toList();
    final preparing = _svc.orders
        .where((o) => o.kitchenStatus == 'preparing')
        .toList();
    final ready = _svc.orders.where((o) => o.kitchenStatus == 'ready').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.kitchenDisplayTitle),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _StatusColumn(
              title: l10n.newColumnTitle,
              color: AppColors.terracottaDark,
              orders: pending,
            ),
          ),
          Expanded(
            child: _StatusColumn(
              title: l10n.preparingColumnTitle,
              color: AppColors.primary,
              orders: preparing,
            ),
          ),
          Expanded(
            child: _StatusColumn(
              title: l10n.readyColumnTitle,
              color: Colors.green.shade700,
              orders: ready,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusColumn extends StatelessWidget {
  const _StatusColumn({
    required this.title,
    required this.color,
    required this.orders,
  });
  final String title;
  final Color color;
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: orders.isEmpty
                ? const SizedBox.shrink()
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.6,
                        ),
                    itemCount: orders.length,
                    itemBuilder: (context, i) => Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color, width: 1.5),
                      ),
                      child: Text(
                        orders[i].formattedNumber,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
