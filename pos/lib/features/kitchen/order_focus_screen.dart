import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../cashier/models/order.dart';
import '../cashier/models/order_item.dart';
import '../cashier/services/menu_service.dart';
import 'services/kitchen_service.dart';

/// Full-screen, one-order-at-a-time view of the live kitchen queue, opened by
/// tapping a Kitchen Display card. Shows each item large (with its menu photo,
/// if enabled in Settings) and lets a barista drive the whole order's prep
/// status from here.
///
/// Pages through the *entire* active queue — prev/next buttons (PC) or a
/// horizontal swipe (touch). Once every item on the current order reads
/// 'ready', a Complete button marks it served and slides to the next order;
/// when the queue empties it returns to the board (never past it).
class OrderFocusScreen extends StatefulWidget {
  const OrderFocusScreen({
    super.key,
    required this.initialOrderId,
    required this.onItemTap,
    required this.onComplete,
  });

  final int initialOrderId;

  /// Advance a single item's prep status (pending → preparing → ready).
  final void Function(Order order, OrderItem item) onItemTap;

  /// Mark the whole order served/completed. Awaited before advancing on.
  final Future<void> Function(Order order) onComplete;

  @override
  State<OrderFocusScreen> createState() => _OrderFocusScreenState();
}

class _OrderFocusScreenState extends State<OrderFocusScreen> {
  bool _showImages = true;
  late int _currentId = widget.initialOrderId;
  int _lastKnownIndex = 0;
  bool _exiting = false;
  bool _completing = false;

  List<Order> get _orders => KitchenService.instance.orders;
  Order? get _current => _orders.where((o) => o.id == _currentId).firstOrNull;
  int get _currentIndex => _orders.indexWhere((o) => o.id == _currentId);

  @override
  void initState() {
    super.initState();
    _loadImagePref();
    // The orders passed through are snapshots; KitchenService is the same live
    // source the board listens to, so item taps and updates from other
    // stations reflect here without closing and reopening.
    KitchenService.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    KitchenService.instance.removeListener(_onChange);
    super.dispose();
  }

  Future<void> _loadImagePref() async {
    final show = await AppSettingsService.instance.getKitchenShowImages();
    if (mounted) setState(() => _showImages = show);
  }

  void _onChange() {
    if (!mounted || _exiting) return;
    if (_current != null) {
      setState(() {});
      return;
    }
    // The order we were on left the live queue (completed/cancelled here or
    // from another station). Slide to whatever order now sits at that slot —
    // or the last one, if we were at the end — and bail to the board only
    // when nothing is left.
    final orders = _orders;
    if (orders.isEmpty) {
      _exit();
      return;
    }
    setState(() => _currentId =
        orders[_lastKnownIndex.clamp(0, orders.length - 1)].id!);
  }

  // Single guarded exit — the KitchenService listener and an in-flight
  // _complete can both discover the queue is empty in the same beat, and two
  // Navigator.pop()s here would fall straight through the board to the hub.
  void _exit() {
    if (_exiting) return;
    _exiting = true;
    Navigator.of(context).pop();
  }

  void _goTo(int index) {
    final orders = _orders;
    if (index < 0 || index >= orders.length) return;
    setState(() {
      _currentId = orders[index].id!;
      _lastKnownIndex = index;
    });
  }

  Future<void> _complete(Order order) async {
    if (_completing || _exiting) return;
    _completing = true;
    try {
      await widget.onComplete(order);
    } finally {
      _completing = false;
    }
    if (!mounted || _exiting) return;
    // updateStatus doesn't touch local state until the server echoes back over
    // the socket, so filter this order out ourselves rather than waiting.
    final remaining = _orders.where((o) => o.id != order.id).toList();
    if (remaining.isEmpty) {
      _exit();
      return;
    }
    setState(() {
      _lastKnownIndex = _lastKnownIndex.clamp(0, remaining.length - 1);
      _currentId = remaining[_lastKnownIndex].id!;
    });
  }

  bool _isComplete(Order o) =>
      o.items.isNotEmpty && o.items.every((i) => i.status == 'ready');

  String? _imageFor(OrderItem item) {
    if (!_showImages) return null;
    final menuItem = MenuService.instance.allItems
        .where((m) => m.id == item.menuItem.id)
        .firstOrNull;
    return menuItem?.imageBase64;
  }

  String _itemLabel(OrderItem item, AppLocalizations l10n, Locale locale) {
    final name = item.menuItem.displayName(locale);
    return item.sweetness == null
        ? name
        : '$name (${item.sweetness!.label(l10n)})';
  }

  Widget _noteBanner(String note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sticky_note_2_outlined, size: 16, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemBox(
      Order order, OrderItem item, AppLocalizations l10n, Locale locale) {
    final image = _imageFor(item);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.terracottaLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                base64Decode(image),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StageChip(status: item.status, l10n: l10n),
                const SizedBox(height: 8),
                Text(
                  '${item.quantity}× ${_itemLabel(item, l10n, locale)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _FocusStatusActions(
                  item: item,
                  l10n: l10n,
                  onTap: () => widget.onItemTap(order, item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final order = _current;
    // _onChange handles the "current order vanished" case; this only shows for
    // the one frame between that notification and its setState.
    if (order == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SizedBox.shrink(),
      );
    }
    final index = _currentIndex;
    _lastKnownIndex = index;
    final total = _orders.length;
    final hasNote = order.note != null && order.note!.isNotEmpty;
    final complete = _isComplete(order);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.focusModeTitle} · ${order.formattedNumber}   ${index + 1}/$total',
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: index > 0 ? () => _goTo(index - 1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: index < total - 1 ? () => _goTo(index + 1) : null,
          ),
          const SizedBox(width: 4),
        ],
      ),
      backgroundColor: AppColors.background,
      // ponytail: swipe is a fling (drag-end velocity), not a finger-following
      // page turn — enough for "next/prev order", and no PageView bookkeeping
      // against a queue that mutates under it.
      body: GestureDetector(
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -250) {
            _goTo(index + 1);
          } else if (v > 250) {
            _goTo(index - 1);
          }
        },
        child: Column(
          children: [
            if (hasNote)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _noteBanner(order.note!),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // One box per row on a phone-width screen; a grid that grows
                  // 2→4 columns as the screen widens (tablet / PC).
                  final cols = constraints.maxWidth < 600
                      ? 1
                      : (constraints.maxWidth / 320).floor().clamp(2, 4);
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisExtent: 150,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: order.items.length,
                    itemBuilder: (context, i) =>
                        _itemBox(order, order.items[i], l10n, locale),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !complete
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed:
                      (_exiting || _completing) ? null : () => _complete(order),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(l10n.completeButton),
                ),
              ),
            ),
    );
  }
}

class _FocusStatusActions extends StatelessWidget {
  const _FocusStatusActions({
    required this.item,
    required this.l10n,
    required this.onTap,
  });
  final OrderItem item;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Full-width so the action reads as a button bar filling the item box,
    // not a pill floating under the title.
    ButtonStyle style([Color? bg]) => ElevatedButton.styleFrom(
      backgroundColor: bg,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );
    return switch (item.status) {
      'pending' => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: style(),
          child: Text(l10n.startPreparingButton),
        ),
      ),
      'preparing' => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: style(AppColors.primary),
          child: Text(l10n.readyToServeButton),
        ),
      ),
      // 'ready' — no per-item action left; the stage chip already shows it.
      _ => const SizedBox.shrink(),
    };
  }
}

/// Always-visible current-stage badge for one item: pending ("not started
/// yet") → preparing → ready. Same colour language as the compact board chip
/// (`_ItemStatusChip` in kitchen_display_screen.dart).
class _StageChip extends StatelessWidget {
  const _StageChip({required this.status, required this.l10n});
  final String status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (status) {
      'preparing' => (
        AppColors.primary,
        l10n.preparingStatusLabel,
        Icons.local_fire_department_outlined,
      ),
      'ready' => (
        Colors.green.shade700,
        l10n.readyStatusLabel,
        Icons.check_circle_outline,
      ),
      _ => (AppColors.muted, l10n.pendingStatusLabel, Icons.schedule),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
