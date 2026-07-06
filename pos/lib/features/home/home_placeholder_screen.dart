import 'package:flutter/material.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../cashier/models/order.dart';
import '../cashier/order_history_screen.dart';
import '../cashier/order_taking_screen.dart';
import '../cashier/services/order_service.dart';
import '../manager/menu_management_screen.dart';
import '../welcome/welcome_screen.dart';

const _kSidebarBg = Color(0xFF232315);
const _kSidebarText = Color(0xFFEEEBCF);
const _kSidebarMuted = Color(0xFF7A7850);
const _kSidebarHighlight = Color(0xFF2E2F18);

class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).width >= Breakpoints.mobile;
    return isWide ? _Desktop(title: title) : _Mobile(title: title);
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

String _dateStr() {
  final d = DateTime.now();
  const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const mo = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${wd[d.weekday - 1]}, ${d.day} ${mo[d.month - 1]} ${d.year}';
}

String _baht(double v) => '฿${v.toStringAsFixed(0)}';

Future<void> _confirmLogout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Sign Out?'),
      content: const Text('You will be returned to the welcome screen.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sign Out',
              style: TextStyle(color: AppColors.terracottaDark)),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }
}

void _comingSoon(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label — coming soon')),
  );
}

void _openNewOrder(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const OrderTakingScreen()),
  );
}

void _openHistory(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
  );
}

void _openMenuMgmt(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const MenuManagementScreen()),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// Desktop layout  — sidebar + content panel
// ════════════════════════════════════════════════════════════════════════════

class _Desktop extends StatelessWidget {
  const _Desktop({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(title: title),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: _ContentPanel(title: title, desktop: true)),
        ],
      ),
    );
  }
}

// ── Sidebar ────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: _kSidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.local_cafe,
                            color: AppColors.accent, size: 14),
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Text(
                      'MinePOS',
                      style: TextStyle(
                        color: _kSidebarText,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Padding(
                  padding: EdgeInsets.only(left: 35),
                  child: Text(
                    'Coffee Shop POS',
                    style: TextStyle(fontSize: 9, color: _kSidebarMuted),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2E2E1A), height: 1),
          // New Order button
          Padding(
            padding: const EdgeInsets.all(14),
            child: GestureDetector(
              onTap: () => _openNewOrder(context),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const Column(
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: AppColors.accent, size: 22),
                    SizedBox(height: 4),
                    Text(
                      'NEW ORDER',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Nav items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  _SideNavItem(
                    icon: Icons.home_outlined,
                    label: 'Dashboard',
                    active: true,
                  ),
                  _SideNavItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Order History',
                    onTap: () => _openHistory(context),
                  ),
                  const SizedBox(height: 6),
                  const Divider(color: Color(0xFF2A2A18), height: 1),
                  const SizedBox(height: 6),
                  _SideNavItem(
                    icon: Icons.restaurant_menu_outlined,
                    label: 'Menu Mgmt',
                    onTap: () => _openMenuMgmt(context),
                  ),
                  _SideNavItem(
                    icon: Icons.soup_kitchen_outlined,
                    label: 'Kitchen',
                    dim: true,
                    onTap: () => _comingSoon(context, 'Kitchen Display'),
                  ),
                  _SideNavItem(
                    icon: Icons.bar_chart_outlined,
                    label: 'Reports',
                    dim: true,
                    onTap: () => _comingSoon(context, 'Reports'),
                  ),
                  _SideNavItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    dim: true,
                    onTap: () => _comingSoon(context, 'Settings'),
                  ),
                ],
              ),
            ),
          ),
          // Footer
          const Divider(color: Color(0xFF2E2E1A), height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Admin',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kSidebarText),
                ),
                GestureDetector(
                  onTap: () => _confirmLogout(context),
                  child: const Icon(Icons.logout,
                      size: 16, color: _kSidebarMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.dim = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final bool dim;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dim ? 0.3 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: active ? _kSidebarHighlight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 16,
                  color: active ? _kSidebarText : _kSidebarMuted),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? _kSidebarText : _kSidebarMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Mobile layout  — bottom nav + body
// ════════════════════════════════════════════════════════════════════════════

class _Mobile extends StatelessWidget {
  const _Mobile({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_cafe, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('MinePOS'),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: _ContentPanel(title: title, desktop: false),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        showUnselectedLabels: true,
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) { _openHistory(context); return; }
          if (i == 2) { _openMenuMgmt(context); return; }
          if (i == 3) { _comingSoon(context, 'Settings'); return; }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Shared content panel
// ════════════════════════════════════════════════════════════════════════════

class _ContentPanel extends StatelessWidget {
  const _ContentPanel({required this.title, required this.desktop});
  final String title;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final svc = OrderService.instance;
    final todayList = svc.todaysOrders;
    final count = todayList.length;
    final revenue = svc.todaysRevenue;
    final avg = count > 0 ? revenue / count : 0.0;
    final recent = svc.orders.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (desktop)
          _TopBar(onLogout: () => _confirmLogout(context)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats
                Row(
                  children: [
                    _StatCard(
                      icon: Icons.receipt_long_outlined,
                      label: 'Orders Today',
                      value: '$count',
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.payments_outlined,
                      label: 'Revenue',
                      value: _baht(revenue),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.bar_chart_outlined,
                      label: 'Avg Order',
                      value: count > 0 ? _baht(avg) : '—',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Recent orders
                _RecentOrders(
                  orders: recent,
                  onViewAll: () => _openHistory(context),
                ),
                // Mobile: New Order button in body
                if (!desktop) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text('NEW ORDER'),
                      onPressed: () => _openNewOrder(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Desktop top bar ────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.terracottaLight)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, Admin',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink),
              ),
              Text(
                _dateStr(),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, size: 15),
            label: const Text('Sign Out'),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.terracottaLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.muted,
                  letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent orders ──────────────────────────────────────────────────────────

class _RecentOrders extends StatelessWidget {
  const _RecentOrders({
    required this.orders,
    required this.onViewAll,
  });
  final List<Order> orders;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RECENT ORDERS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.15,
                color: AppColors.muted,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('View all →',
                  style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        orders.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.terracottaLight),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 32,
                        color: AppColors.muted),
                    SizedBox(height: 8),
                    Text(
                      'No orders yet today',
                      style: TextStyle(
                          color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.terracottaLight),
                ),
                child: Column(
                  children: orders.asMap().entries.map((e) {
                    final i = e.key;
                    final o = e.value;
                    final isLast = i == orders.length - 1;
                    final itemSummary = o.items
                        .map((item) => '${item.quantity}× ${item.menuItem.name}')
                        .join(', ');
                    final methodLabel = o.paymentMethod == PaymentMethod.cash
                        ? 'Cash'
                        : 'QR';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : const Border(
                                bottom: BorderSide(
                                    color: AppColors.terracottaLight,
                                    width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            o.formattedNumber,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              itemSummary,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _baht(o.total),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              methodLabel,
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
      ],
    );
  }
}
