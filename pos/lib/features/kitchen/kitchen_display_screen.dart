import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../cashier/models/order.dart';
import '../cashier/models/order_item.dart';
import '../welcome/welcome_screen.dart';
import 'services/kitchen_service.dart';

/// Item statuses advance pending → preparing → ready; null once at 'ready'
/// since further progress ("served") is an order-level action.
String? _nextItemStatus(String current) => switch (current) {
      'pending' => 'preparing',
      'preparing' => 'ready',
      _ => null,
    };

const _kUrgentAge = Duration(minutes: 5);

Future<void> _confirmLogout(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(l10n.signOutDialogTitle),
      content: Text(l10n.signOutDialogContent),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.signOut,
              style: const TextStyle(color: AppColors.terracottaDark)),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    ServerClient.instance.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }
}

class KitchenDisplayScreen extends StatefulWidget {
  const KitchenDisplayScreen({super.key, this.standalone = false});

  /// True when this device was set up as a kitchen-only station (Role
  /// Selection → Kitchen Display) and landed here directly with no hub in
  /// the navigation stack to sign out from — so this screen needs its own
  /// logout affordance.
  final bool standalone;

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
        SnackBar(content: Text(AppLocalizations.of(context)!.updateOrderErrorSnackbar('$e')),
            backgroundColor: AppColors.terracottaDark),
      );
    }
  }

  Future<void> _advanceItem(Order order, OrderItem item) async {
    final next = _nextItemStatus(item.status);
    if (next == null || item.id == null) return;
    try {
      await _svc.updateItemStatus(order.id!, item.id!, next);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.updateItemErrorSnackbar('$e')),
            backgroundColor: AppColors.terracottaDark),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pending = _svc.orders.where((o) => o.kitchenStatus == 'pending').toList();
    final preparing = _svc.orders.where((o) => o.kitchenStatus == 'preparing').toList();
    final ready = _svc.orders.where((o) => o.kitchenStatus == 'ready').toList();
    final isMobile = Responsive.isMobile(context);

    final columns = [
      _KitchenColumn(
        title: l10n.newColumnTitle,
        color: AppColors.terracottaDark,
        orders: pending,
        onItemTap: _advanceItem,
      ),
      _KitchenColumn(
        title: l10n.preparingColumnTitle,
        color: AppColors.primary,
        orders: preparing,
        onItemTap: _advanceItem,
      ),
      _KitchenColumn(
        title: l10n.readyColumnTitle,
        color: Colors.green.shade700,
        orders: ready,
        onItemTap: _advanceItem,
        completeLabel: l10n.completeButton,
        onComplete: (o) => _advance(o, 'completed'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.kitchenDisplayTitle),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _ConnectionBadge(state: _svc.state)),
          ),
          if (widget.standalone)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: l10n.signOutTooltip,
              onPressed: () => _confirmLogout(context),
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
    final l10n = AppLocalizations.of(context)!;
    final (color, label) = switch (state) {
      KitchenConnectionState.connected => (Colors.green.shade700, l10n.liveConnectionLabel),
      KitchenConnectionState.connecting => (AppColors.muted, l10n.connectingLabel),
      KitchenConnectionState.error => (AppColors.terracottaDark, l10n.reconnectingLabel),
      KitchenConnectionState.disconnected => (AppColors.muted, l10n.offlineLabel),
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
    required this.onItemTap,
    this.completeLabel,
    this.onComplete,
  });
  final String title;
  final Color color;
  final List<Order> orders;
  final void Function(Order order, OrderItem item) onItemTap;

  /// Only set for the READY column — the whole-order "served" action, shown
  /// once every item on a card reads 'ready'.
  final String? completeLabel;
  final ValueChanged<Order>? onComplete;

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
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(AppLocalizations.of(context)!.kitchenNoOrders,
                          style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ),
                  )
                : ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _OrderCard(
                      order: orders[i],
                      onItemTap: (item) => onItemTap(orders[i], item),
                      completeLabel: completeLabel,
                      onComplete:
                          onComplete == null ? null : () => onComplete!(orders[i]),
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
    required this.onItemTap,
    this.completeLabel,
    this.onComplete,
  });
  final Order order;
  final ValueChanged<OrderItem> onItemTap;
  final String? completeLabel;
  final VoidCallback? onComplete;

  String _elapsed(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mins = DateTime.now().difference(order.createdAt).inMinutes;
    if (mins < 1) return l10n.justNowElapsed;
    if (mins == 1) return l10n.oneMinAgoElapsed;
    return l10n.minAgoElapsed(mins);
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
                _elapsed(context),
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
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Text('${item.quantity}×',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(item.menuItem.name, style: const TextStyle(fontSize: 13)),
                  ),
                  _ItemStatusChip(item: item, onTap: () => onItemTap(item)),
                ],
              ),
            ),
          ),
          if (completeLabel != null && onComplete != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onComplete,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                child: Text(completeLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemStatusChip extends StatelessWidget {
  const _ItemStatusChip({required this.item, required this.onTap});
  final OrderItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (color, label) = switch (item.status) {
      'preparing' => (AppColors.primary, l10n.preparingStatusLabel),
      'ready' => (Colors.green.shade700, l10n.readyStatusLabel),
      _ => (AppColors.muted, l10n.pendingStatusLabel),
    };
    final tappable = _nextItemStatus(item.status) != null;
    return GestureDetector(
      onTap: tappable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: tappable ? 0.6 : 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }
}
