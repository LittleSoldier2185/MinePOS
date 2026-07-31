import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/menu_sort_button.dart';
import '../../l10n/app_localizations.dart';
import '../customer_display/services/customer_display_service.dart';
import '../manager/services/promotion_admin_service.dart';
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
  final _menuService = MenuService.instance;
  TabController? _tabController;

  // A brand-new shop can genuinely have zero menu items (none added in
  // Menu Management yet) — .first would throw on that empty list.
  String _selectedCategory = MenuService.instance.categories.isEmpty
      ? ''
      : MenuService.instance.categories.first;
  final List<OrderItem> _cart = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final _noteController = TextEditingController();
  MenuSortMode _sortMode = MenuSortMode.defaultOrder;
  List<Promotion> _combos = [];

  // Set once this cart has actually been handed to PaymentScreen, so dispose()
  // doesn't re-hold a cart that was already sold (see pushAndRemoveUntil in
  // receipt_screen.dart, which disposes this screen after a completed sale).
  bool _sentToPayment = false;

  // Survives this State being destroyed (e.g. the cashier backs out to Home
  // mid-order) so the next OrderTakingScreen instance can resume it — see
  // dispose() / the restore in initState().
  static List<OrderItem>? _heldCart;
  static String? _heldNote;

  int get _cartCount => _cart.fold(0, (s, i) => s + i.quantity);
  double get _cartTotal => _cart.fold(0.0, (s, i) => s + i.subtotal);

  @override
  void initState() {
    super.initState();
    CustomerDisplayService.instance.connect();
    _menuService.addListener(_onMenuChanged);
    AppSettingsService.instance.getMenuSortMode().then((v) {
      if (mounted) setState(() => _sortMode = v);
    });
    _loadCombos();
    if (_heldCart != null && _heldCart!.isNotEmpty) {
      _cart.addAll(_heldCart!);
      _heldCart = null;
      _noteController.text = _heldNote ?? '';
      _heldNote = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncDisplay();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.heldOrderResumedMessage,
            ),
          ),
        );
      });
    }
  }

  // Menu edits made on another device (new item, price change, item toggled
  // off, etc.) arrive over MenuService's own /ws/menu connection; this just
  // triggers a rebuild so the grid here reflects them without a re-login.
  void _onMenuChanged() {
    if (!mounted) return;
    setState(() {
      // Keep the selection valid as the menu changes live — covers both a
      // once-empty menu gaining its first item and the selected category
      // itself being deleted out from under this screen.
      final categories = _menuService.categories;
      if (!categories.contains(_selectedCategory) && categories.isNotEmpty) {
        _selectedCategory = categories.first;
      }
    });
  }

  Future<void> _loadCombos() async {
    try {
      final promotions = await PromotionAdminService.instance.list();
      if (!mounted) return;
      setState(() {
        _combos = promotions
            .where((p) => p.type == 'combo' && p.active)
            .toList();
      });
    } catch (_) {
      // Combo shortcuts are a convenience on top of manually adding the same
      // items — nothing breaks by just not offering them this session.
    }
  }

  // ── Cart helpers ──────────────────────────────────────────────────────────

  void _syncDisplay() {
    final nextNum = OrderService.instance.nextOrderNumber.toString().padLeft(
      3,
      '0',
    );
    CustomerDisplayService.instance.publishCart(
      items: _cart,
      total: _cartTotal,
      orderNumber: nextNum,
    );
  }

  Future<void> _addItem(MenuItem item) async {
    SweetnessLevel? sweetness;
    if (item.hasSweetness) {
      sweetness = await _pickSweetness();
      if (sweetness == null) return;
    }
    setState(() {
      final existing = _cart
          .where((i) => i.menuItem.id == item.id && i.sweetness == sweetness)
          .firstOrNull;
      if (existing != null) {
        existing.quantity++;
      } else {
        _cart.add(OrderItem(menuItem: item, sweetness: sweetness));
      }
    });
    _syncDisplay();
  }

  /// Adds one of every menu item that makes up [combo]'s bundle — the same
  /// as the cashier tapping each item individually, just in one action. Any
  /// bundled item that's since been deleted/marked unavailable is silently
  /// skipped (the discount itself just won't apply until the cashier adds a
  /// substitute, same as if they'd forgotten to add it manually).
  Future<void> _addCombo(Promotion combo) async {
    for (final item in resolveComboItems(
      combo.scopeItemIds,
      _menuService.allAvailable,
    )) {
      await _addItem(item);
    }
  }

  Future<void> _pickCombo() async {
    final l10n = AppLocalizations.of(context)!;
    final combo = await showModalBottomSheet<Promotion>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                l10n.comboBundlesTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            for (final combo in _combos)
              ListTile(
                title: Text(combo.name),
                subtitle: Text(
                  l10n.comboPriceLabel(baht(combo.comboPrice ?? 0)),
                ),
                onTap: () => Navigator.pop(context, combo),
              ),
          ],
        ),
      ),
    );
    if (combo != null) await _addCombo(combo);
  }

  Future<SweetnessLevel?> _pickSweetness() {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<SweetnessLevel>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                l10n.selectSweetnessTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            for (final level in SweetnessLevel.values)
              ListTile(
                title: Text(level.label(l10n)),
                onTap: () => Navigator.pop(context, level),
              ),
          ],
        ),
      ),
    );
  }

  void _increment(int index) {
    setState(() => _cart[index].quantity++);
    _syncDisplay();
  }

  void _decrement(int index) {
    setState(() {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
      } else {
        _cart.removeAt(index);
      }
    });
    _syncDisplay();
  }

  void _remove(int index) {
    setState(() => _cart.removeAt(index));
    _syncDisplay();
  }

  Future<void> _clearCart() async {
    if (_cart.isEmpty) return;
    final confirmed = await confirmDialog(
      context,
      title: AppLocalizations.of(context)!.clearOrderDialogTitle,
      content: AppLocalizations.of(context)!.clearOrderDialogContent,
      confirmLabel: AppLocalizations.of(context)!.clearButton,
      cancelLabel: AppLocalizations.of(context)!.cancel,
    );
    if (confirmed) {
      setState(() => _cart.clear());
      _syncDisplay();
    }
  }

  Future<void> _proceedToPayment() async {
    if (_cart.isEmpty) return;
    _sentToPayment = true;
    // A completed sale leaves this screen via ReceiptScreen's
    // pushAndRemoveUntil, which removes this route outright — so reaching
    // this line means payment was cancelled/backed out of instead, and this
    // same cart is still live and should go back to being holdable.
    final note = _noteController.text.trim();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          items: List.from(_cart),
          note: note.isEmpty ? null : note,
        ),
      ),
    );
    _sentToPayment = false;
  }

  void _setSortMode(MenuSortMode mode) {
    setState(() => _sortMode = mode);
    AppSettingsService.instance.setMenuSortMode(mode);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= Breakpoints.mobile;
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
            Tab(text: AppLocalizations.of(context)!.menuLabel),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.cartTabLabel),
                  if (_cartCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_cartCount',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
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
      title: Row(
        children: [
          const Icon(Icons.local_cafe, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.newOrderAppBarTitle),
        ],
      ),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: [
        if (_combos.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.local_offer_outlined),
            tooltip: AppLocalizations.of(context)!.comboBundlesTitle,
            onPressed: _pickCombo,
          ),
        MenuSortButton(value: _sortMode, onChanged: _setSortMode),
        if (_cart.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: AppLocalizations.of(context)!.clearOrderTooltip,
            onPressed: _clearCart,
          ),
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: AppLocalizations.of(context)!.orderHistoryTooltip,
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
        ),
      ],
      bottom: bottom,
    );
  }

  // ── Menu panel ────────────────────────────────────────────────────────────

  Widget _buildMenuPanel() {
    if (_menuService.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 56,
              color: AppColors.muted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.noMenuItemsMessage,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    final query = _searchQuery.trim().toLowerCase();
    final locale = Localizations.localeOf(context);
    final unsorted = query.isEmpty
        ? _menuService.itemsForCategory(_selectedCategory)
        : _menuService.allAvailable
              .where((i) => i.displayName(locale).toLowerCase().contains(query))
              .toList();
    final items = sortMenuItems(unsorted, _sortMode, locale);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              isDense: true,
              hintText: AppLocalizations.of(context)!.searchMenuHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      }),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.terracottaLight),
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        if (query.isEmpty)
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: _menuService.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _menuService.categories[i];
                final selected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
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
                        color: selected ? AppColors.accent : AppColors.ink,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (query.isNotEmpty && items.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.noSearchResultsMessage,
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          )
        else
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cols = (constraints.maxWidth / 140).floor().clamp(2, 5);
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
                    final matches = _cart.where(
                      (i) => i.menuItem.id == item.id,
                    );
                    final qty = matches.isEmpty
                        ? null
                        : matches.fold(0, (s, i) => s + i.quantity);
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
    final nextNum = OrderService.instance.nextOrderNumber.toString().padLeft(
      3,
      '0',
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.terracottaLight),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!.orderNumberLabel(nextNum),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                AppLocalizations.of(context)!.itemsCount(_cartCount),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: _cart.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.emptyCartMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, height: 1.6),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _cart.length,
                  itemBuilder: (context, index) => _CartItemRow(
                    item: _cart[index],
                    baht: baht,
                    onIncrement: () => _increment(index),
                    onDecrement: () => _decrement(index),
                    onRemove: () => _remove(index),
                  ),
                ),
        ),
        if (_cart.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _noteController,
              maxLines: 2,
              minLines: 1,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: AppLocalizations.of(context)!.orderNoteHint,
                prefixIcon: const Icon(Icons.edit_note, size: 20),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.terracottaLight,
                  ),
                ),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.terracottaLight)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.total,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    baht(_cartTotal),
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
                  onPressed: _cart.isNotEmpty ? _proceedToPayment : null,
                  child: Text(AppLocalizations.of(context)!.proceedToPayButton),
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
    if (!_sentToPayment && _cart.isNotEmpty) {
      _heldCart = List<OrderItem>.of(_cart);
      _heldNote = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();
    }
    _menuService.removeListener(_onMenuChanged);
    _searchController.dispose();
    _noteController.dispose();
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
            color: inCart ? AppColors.primary : AppColors.terracottaLight,
            width: inCart ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.imageBase64 != null
                        ? Image.memory(
                            base64Decode(item.imageBase64!),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: double.infinity,
                            color: AppColors.background,
                            child: const Icon(
                              Icons.fastfood_outlined,
                              size: 18,
                              color: AppColors.muted,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.displayName(Localizations.localeOf(context)),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: inCart ? AppColors.primary : AppColors.ink,
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
                    fontWeight: FontWeight.w500,
                  ),
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
                        fontWeight: FontWeight.bold,
                      ),
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
    final name = item.menuItem.displayName(Localizations.localeOf(context));
    final label = item.sweetness == null
        ? name
        : '$name (${item.sweetness!.label(AppLocalizations.of(context)!)})';
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 4),
          _QtyButton(icon: Icons.add, onTap: onIncrement),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(baht(item.subtotal), style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: AppColors.muted),
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
