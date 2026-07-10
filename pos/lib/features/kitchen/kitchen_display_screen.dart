import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../cashier/models/order.dart';
import 'services/kitchen_service.dart';

const _kUrgentAge = Duration(minutes: 5);

class KitchenDisplayScreen extends StatefulWidget {
  const KitchenDisplayScreen({super.key});

  @override
  State<KitchenDisplayScreen> createState() => _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends State<KitchenDisplayScreen> {
  final _svc = KitchenService.instance;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onChange);
    _svc.connect();
    // Re-render periodically so "elapsed" labels and urgency highlighting
    // stay current even when no new WebSocket events arrive.
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _svc.removeListener(_onChange);
    _svc.disconnect();
    _ticker?.cancel();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _advance(Order order, String nextStatus) async {
    try {
      await _svc.updateStatus(order.id!, nextStatus);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update order: $e'),
            backgroundColor: AppColors.terracottaDark),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _svc.orders.where((o) => o.kitchenStatus == 'pending').toList();
    final preparing = _svc.orders.where((o) => o.kitchenStatus == 'preparing').toList();
    final ready = _svc.orders.where((o) => o.kitchenStatus == 'ready').toList();
    final isMobile = Responsive.isMobile(context);

    final columns = [
      _KitchenColumn(
        title: 'NEW',
        color: AppColors.terracottaDark,
        orders: pending,
        actionLabel: 'Start Preparing',
        onAction: (o) => _advance(o, 'preparing'),
      ),
      _KitchenColumn(
        title: 'PREPARING',
        color: AppColors.primary,
        orders: preparing,
        actionLabel: 'Mark Ready',
        onAction: (o) => _advance(o, 'ready'),
      ),
      _KitchenColumn(
        title: 'READY',
        color: Colors.green.shade700,
        orders: ready,
        actionLabel: 'Complete',
        onAction: (o) => _advance(o, 'completed'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Display'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _ConnectionBadge(state: _svc.state)),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: isMobile
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: columns
                    .map((c) => SizedBox(width: 320, child: c))
                    .toList(),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: columns.map((c) => Expanded(child: c)).toList(),
            ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.state});
  final KitchenConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (state) {
      KitchenConnectionState.connected => (Colors.green.shade700, 'Live'),
      KitchenConnectionState.connecting => (AppColors.muted, 'Connecting…'),
      KitchenConnectionState.error => (AppColors.terracottaDark, 'Reconnecting…'),
      KitchenConnectionState.disconnected => (AppColors.muted, 'Offline'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _KitchenColumn extends StatelessWidget {
  const _KitchenColumn({
    required this.title,
    required this.color,
    required this.orders,
    required this.actionLabel,
    required this.onAction,
  });
  final String title;
  final Color color;
  final List<Order> orders;
  final String actionLabel;
  final ValueChanged<Order> onAction;

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
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Text(
                title,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: color),
              ),
              const SizedBox(width: 6),
              Text('${orders.length}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: orders.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text('No orders', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ),
                  )
                : ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _OrderCard(
                      order: orders[i],
                      actionLabel: actionLabel,
                      onAction: () => onAction(orders[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.actionLabel,
    required this.onAction,
  });
  final Order order;
  final String actionLabel;
  final VoidCallback onAction;

  String _elapsed() {
    final mins = DateTime.now().difference(order.createdAt).inMinutes;
    if (mins < 1) return 'just now';
    if (mins == 1) return '1 min ago';
    return '$mins min ago';
  }

  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().difference(order.createdAt);
    final urgent = order.kitchenStatus != 'ready' && age >= _kUrgentAge;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: urgent ? AppColors.terracottaDark : AppColors.terracottaLight,
            width: urgent ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.formattedNumber,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
              Text(
                _elapsed(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: urgent ? FontWeight.w700 : FontWeight.w500,
                  color: urgent ? AppColors.terracottaDark : AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text('${item.quantity}×',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(item.menuItem.name, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
