import 'package:flutter/material.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import 'models/menu_item.dart';
import 'models/order_item.dart';
import 'order_history_screen.dart';
import 'payment_screen.dart';
import 'services/menu_service.dart';
import 'services/order_service.dart';

class OrderTakingScreen extends StatefulWidget {
  const OrderTakingScreen({super.key});

  @override
  State<OrderTakingScreen> createState() => _OrderTakingScreenState();
}

class _OrderTakingScreenState extends State<OrderTakingScreen>
    with SingleTickerProviderStateMixin {
  final _menuService = MenuService();
  TabController? _tabController;

  String _selectedCategory = MenuService.categories.first;
  final List<OrderItem> _cart = [];

  int get _cartCount => _cart.fold(0, (s, i) => s + i.quantity);
  double get _cartTotal => _cart.fold(0.0, (s, i) => s + i.subtotal);

  String _baht(double v) => '฿${v.toStringAsFixed(0)}';

  // ── Cart helpers ──────────────────────────────────────────────────────────

  void _addItem(MenuItem item) {
    setState(() {
      final existing =
          _cart.where((i) => i.menuItem.id == item.id).firstOrNull;
      if (existing != null) {
        existing.quantity++;
      } else {
        _cart.add(OrderItem(menuItem: item));
      }
    });
  }

  void _increment(int index) => setState(() => _cart[index].quantity++);

  void _decrement(int index) {
    setState(() {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
      } else {
        _cart.removeAt(index);
      }
    });
  }

  void _remove(int index) => setState(() => _cart.removeAt(index));

  Future<void> _clearCart() async {
    if (_cart.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Order?'),
        content: const Text('Remove all items from the current order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear',
                style: TextStyle(color: AppColors.terracottaDark)),
          ),
        ],
      ),
    );
    if (confirmed == true) setState(() => _cart.clear());
  }

  void _proceedToPayment() {
    if (_cart.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(items: List.from(_cart)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).width >= Breakpoints.mobile;
    return isWide ? _buildWideLayout() : _buildNarrowLayout();
  }

  Widget _buildWideLayout() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Row(
        children: [
          Expanded(flex: 3, child: _buildMenuPanel()),
          const VerticalDivider(width: 1, thickness: 1),
          SizedBox(width: 260, child: _buildCartPanel()),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    _tabController ??= TabController(length: 2, vsync: this);
    return Scaffold(
      appBar: _buildAppBar(
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          tabs: [
            const Tab(text: 'Menu'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Cart'),
                  if (_cartCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_cartCount',
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMenuPanel(), _buildCartPanel()],
      ),
    );
  }

  AppBar _buildAppBar({PreferredSizeWidget? bottom}) {
    return AppBar(
      title: const Row(
        children: [
          Icon(Icons.local_cafe, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('New Order'),
        ],
      ),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: [
        if (_cart.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear order',
            onPressed: _clearCart,
          ),
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Order history',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
          ),
        ),
      ],
      bottom: bottom,
    );
  }

  // ── Menu panel ────────────────────────────────────────────────────────────

  Widget _buildMenuPanel() {
    final items = _menuService.itemsForCategory(_selectedCategory);

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView.separated(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            scrollDirection: Axis.horizontal,
            itemCount: MenuService.categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = MenuService.categories[i];
              final selected = cat == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.terracottaLight,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? AppColors.accent : AppColors.ink,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cols =
                  (constraints.maxWidth / 140).floor().clamp(2, 5);
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.1,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final qty = _cart
                      .where((i) => i.menuItem.id == item.id)
                      .map((i) => i.quantity)
                      .firstOrNull;
                  return _MenuItemCard(
                    item: item,
                    cartQty: qty,
                    onTap: () => _addItem(item),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Cart panel ────────────────────────────────────────────────────────────

  Widget _buildCartPanel() {
    final nextNum = OrderService.instance.nextOrderNumber
        .toString()
        .padLeft(3, '0');

    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
                bottom: BorderSide(color: AppColors.terracottaLight)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order  #$nextNum',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '$_cartCount item${_cartCount == 1 ? '' : 's'}',
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: _cart.isEmpty
              ? const Center(
                  child: Text(
                    'Tap items\nto add to order',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, height: 1.6),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _cart.length,
                  itemBuilder: (context, index) => _CartItemRow(
                    item: _cart[index],
                    baht: _baht,
                    onIncrement: () => _increment(index),
                    onDecrement: () => _decrement(index),
                    onRemove: () => _remove(index),
                  ),
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
                top: BorderSide(color: AppColors.terracottaLight)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    _baht(_cartTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _cart.isNotEmpty ? _proceedToPayment : null,
                  child: const Text('PROCEED TO PAY'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}

// ── Menu item card ─────────────────────────────────────────────────────────────

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({
    required this.item,
    required this.cartQty,
    required this.onTap,
  });
  final MenuItem item;
  final int? cartQty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inCart = (cartQty ?? 0) > 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: inCart
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                inCart ? AppColors.primary : AppColors.terracottaLight,
            width: inCart ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        inCart ? AppColors.primary : AppColors.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '฿${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (inCart)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$cartQty',
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Cart item row ─────────────────────────────────────────────────────────────

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.baht,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });
  final OrderItem item;
  final String Function(double) baht;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _QtyButton(icon: Icons.remove, onTap: onDecrement),
          const SizedBox(width: 4),
          SizedBox(
            width: 24,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 4),
          _QtyButton(icon: Icons.add, onTap: onIncrement),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.menuItem.name,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(baht(item.subtotal),
              style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close,
                size: 16, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.terracottaLight),
        ),
        child: Icon(icon, size: 14, color: AppColors.primary),
      ),
    );
  }
}
