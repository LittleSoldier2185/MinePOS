import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../cashier/models/order.dart';
import '../cashier/order_history_screen.dart';
import '../cashier/order_taking_screen.dart';
import '../cashier/services/order_service.dart';
import '../connect/services/connection_service.dart';
import '../kitchen/kitchen_display_screen.dart';
import '../manager/menu_management_screen.dart';
import '../manager/reports_screen.dart';
import '../manager/settings_screen.dart';
import '../manager/staff_management_screen.dart';
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
    final isWide = MediaQuery.sizeOf(context).width >= Breakpoints.mobile;
    return isWide ? _Desktop(title: title) : _Mobile(title: title);
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────

String _greeting(BuildContext context) {
  final h = DateTime.now().hour;
  if (h < 12) return AppLocalizations.of(context)!.goodMorningGreeting;
  if (h < 17) return AppLocalizations.of(context)!.goodAfternoonGreeting;
  return AppLocalizations.of(context)!.goodEveningGreeting;
}

String _dateStr(BuildContext context) {
  final d = DateTime.now();
  return DateFormat(
    'EEE, d MMM yyyy',
    Localizations.localeOf(context).toString(),
  ).format(d);
}

String _baht(double v) => '฿${v.toStringAsFixed(0)}';

Future<void> _confirmLogout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.signOutDialogTitle),
      content: Text(AppLocalizations.of(context)!.signOutDialogContent),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            AppLocalizations.of(context)!.signOut,
            style: const TextStyle(color: AppColors.terracottaDark),
          ),
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

void _openNewOrder(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const OrderTakingScreen()));
}

void _openHistory(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
}

void _openMenuMgmt(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const MenuManagementScreen()));
}

void _openReports(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
}

void _openSettings(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
}

void _openStaff(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const StaffManagementScreen()));
}

void _openKitchen(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const KitchenDisplayScreen()));
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
                        child: Icon(
                          Icons.local_cafe,
                          color: AppColors.accent,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      AppLocalizations.of(context)!.appName,
                      style: const TextStyle(
                        color: _kSidebarText,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 35),
                  child: Text(
                    AppLocalizations.of(context)!.appTagline,
                    style: const TextStyle(fontSize: 9, color: _kSidebarMuted),
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
                child: Column(
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.accent,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.newOrderButton,
                      style: const TextStyle(
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
                    label: AppLocalizations.of(
                      context,
                    )!.desktopDashboardNavLabel,
                    active: true,
                  ),
                  _SideNavItem(
                    icon: Icons.receipt_long_outlined,
                    label: AppLocalizations.of(context)!.orderHistoryLabel,
                    onTap: () => _openHistory(context),
                  ),
                  const SizedBox(height: 6),
                  const Divider(color: Color(0xFF2A2A18), height: 1),
                  const SizedBox(height: 6),
                  if (ServerClient.instance.canManageShop)
                    _SideNavItem(
                      icon: Icons.restaurant_menu_outlined,
                      label: AppLocalizations.of(context)!.menuMgmtNavLabel,
                      onTap: () => _openMenuMgmt(context),
                    ),
                  _SideNavItem(
                    icon: Icons.soup_kitchen_outlined,
                    label: AppLocalizations.of(context)!.kitchenNavLabel,
                    onTap: () => _openKitchen(context),
                  ),
                  if (ServerClient.instance.canManageShop)
                    _SideNavItem(
                      icon: Icons.bar_chart_outlined,
                      label: AppLocalizations.of(context)!.reportsLabel,
                      onTap: () => _openReports(context),
                    ),
                  if (ServerClient.instance.isOwner)
                    _SideNavItem(
                      icon: Icons.badge_outlined,
                      label: AppLocalizations.of(context)!.staffLabel,
                      onTap: () => _openStaff(context),
                    ),
                  _SideNavItem(
                    icon: Icons.settings_outlined,
                    label: AppLocalizations.of(context)!.settingsLabel,
                    onTap: () => _openSettings(context),
                  ),
                ],
              ),
            ),
          ),
          // Footer
          const Divider(color: Color(0xFF2E2E1A), height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 11, 18, 0),
            child: _ConnectionStatus(mutedColor: _kSidebarMuted),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ServerClient.instance.username ??
                      AppLocalizations.of(context)!.defaultAdminUsername,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kSidebarText,
                  ),
                ),
                GestureDetector(
                  onTap: () => _confirmLogout(context),
                  child: const Icon(
                    Icons.logout,
                    size: 16,
                    color: _kSidebarMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Connection status ─────────────────────────────────────────────────────

/// Polls `/health` on the connected server periodically and shows a
/// Live/Offline dot — same visual language as the kitchen display's
/// WebSocket badge, but for the plain HTTP connection this screen relies on.
class _ConnectionStatus extends StatefulWidget {
  const _ConnectionStatus({this.mutedColor = AppColors.muted});
  final Color mutedColor;

  @override
  State<_ConnectionStatus> createState() => _ConnectionStatusState();
}

class _ConnectionStatusState extends State<_ConnectionStatus> {
  final _svc = ConnectionService();
  bool? _connected;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _check());
  }

  Future<void> _check() async {
    final address = ServerClient.instance.baseUrl;
    final ok = address != null && await _svc.testConnection(address);
    if (mounted) setState(() => _connected = ok);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (color, label) = switch (_connected) {
      true => (Colors.green.shade700, l10n.liveConnectionLabel),
      false => (AppColors.terracottaDark, l10n.offlineLabel),
      null => (widget.mutedColor, l10n.connectingLabel),
    };
    return Tooltip(
      message: ServerClient.instance.baseUrl ?? '',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
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
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            Icon(
              icon,
              size: 16,
              color: active ? _kSidebarText : _kSidebarMuted,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? _kSidebarText : _kSidebarMuted,
              ),
            ),
          ],
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
        title: Row(
          children: [
            const Icon(Icons.local_cafe, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.appName),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Center(child: _ConnectionStatus()),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'kitchen',
                child: Text(AppLocalizations.of(context)!.kitchenNavLabel),
              ),
              if (ServerClient.instance.canManageShop)
                PopupMenuItem(
                  value: 'reports',
                  child: Text(AppLocalizations.of(context)!.reportsLabel),
                ),
              if (ServerClient.instance.isOwner)
                PopupMenuItem(
                  value: 'staff',
                  child: Text(AppLocalizations.of(context)!.staffLabel),
                ),
            ],
            onSelected: (value) {
              if (value == 'kitchen') _openKitchen(context);
              if (value == 'reports') _openReports(context);
              if (value == 'staff') _openStaff(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: _ContentPanel(title: title, desktop: false),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // Tab actions are filtered by role, so build (item, onTap) pairs together
  // rather than hardcoding tab indices — hiding "Menu" for employees must
  // not shift what the remaining tabs do.
  Widget _buildBottomNav(BuildContext context) {
    final canManage = ServerClient.instance.canManageShop;
    final entries = <(BottomNavigationBarItem, VoidCallback?)>[
      (
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: AppLocalizations.of(context)!.mobileBottomNavHome,
        ),
        null,
      ),
      (
        BottomNavigationBarItem(
          icon: const Icon(Icons.receipt_long_outlined),
          activeIcon: const Icon(Icons.receipt_long),
          label: AppLocalizations.of(context)!.mobileBottomNavOrders,
        ),
        () => _openHistory(context),
      ),
      if (canManage)
        (
          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant_menu_outlined),
            label: AppLocalizations.of(context)!.menuLabel,
          ),
          () => _openMenuMgmt(context),
        ),
      (
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings_outlined),
          label: AppLocalizations.of(context)!.settingsLabel,
        ),
        () => _openSettings(context),
      ),
    ];

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.muted,
      showUnselectedLabels: true,
      currentIndex: 0,
      onTap: (i) => entries[i].$2?.call(),
      items: entries.map((e) => e.$1).toList(),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Shared content panel
// ════════════════════════════════════════════════════════════════════════════

class _ContentPanel extends StatefulWidget {
  const _ContentPanel({required this.title, required this.desktop});
  final String title;
  final bool desktop;

  @override
  State<_ContentPanel> createState() => _ContentPanelState();
}

class _ContentPanelState extends State<_ContentPanel> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // OrderService is a plain singleton, not listenable — popping back here
    // after completing an order doesn't rebuild this (already-built) widget
    // on its own, so the stats looked frozen until something else happened
    // to trigger a rebuild. Polling is the same fix already used for the
    // connection-status dot further down this file.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = widget.desktop;
    final svc = OrderService.instance;
    final todayList = svc.todaysOrders;
    final count = todayList.length;
    final revenue = svc.todaysRevenue;
    final avg = count > 0 ? revenue / count : 0.0;
    final recent = svc.orders.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (desktop) _TopBar(onLogout: () => _confirmLogout(context)),
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
                      label: AppLocalizations.of(context)!.homeOrdersTodayStat,
                      value: '$count',
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.payments_outlined,
                      label: AppLocalizations.of(context)!.revenueLabel,
                      value: _baht(revenue),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.bar_chart_outlined,
                      label: AppLocalizations.of(context)!.avgOrderLabel,
                      value: count > 0
                          ? _baht(avg)
                          : AppLocalizations.of(context)!.emDash,
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
                      label: Text(AppLocalizations.of(context)!.newOrderButton),
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
                AppLocalizations.of(
                  context,
                )!.greetingWithName(_greeting(context)),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                _dateStr(context),
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, size: 15),
            label: Text(AppLocalizations.of(context)!.signOut),
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
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent orders ──────────────────────────────────────────────────────────

class _RecentOrders extends StatelessWidget {
  const _RecentOrders({required this.orders, required this.onViewAll});
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
            Text(
              AppLocalizations.of(context)!.recentOrdersHeader,
              style: const TextStyle(
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
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppLocalizations.of(context)!.viewAllOrdersLink,
                style: const TextStyle(fontSize: 12),
              ),
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
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 32,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.noOrdersTodayMessage,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
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
                        .map(
                          (item) =>
                              '${item.quantity}× ${item.menuItem.displayName(Localizations.localeOf(context))}',
                        )
                        .join(', ');
                    final methodLabel = o.paymentMethod == PaymentMethod.cash
                        ? AppLocalizations.of(context)!.cash
                        : AppLocalizations.of(context)!.recentOrderQrLabel;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : const Border(
                                bottom: BorderSide(
                                  color: AppColors.terracottaLight,
                                  width: 0.5,
                                ),
                              ),
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
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              methodLabel,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
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
