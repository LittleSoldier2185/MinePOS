import 'package:flutter/material.dart';

import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../manager/menu_management_screen.dart';
import '../manager/reports_screen.dart';
import '../manager/settings_screen.dart';
import '../manager/staff_management_screen.dart';
import 'mobile_bottom_nav.dart';

/// Mobile "More" tab — replaces the old AppBar overflow (⋮) popup with a
/// real screen, so it also gets the shared bottom nav/New Order FAB like
/// every other tab destination, instead of a popup menu with none of that.
/// Lists exactly what the popup used to (Menu/Reports/Staff, each still
/// role-gated) plus Settings, which used to be its own separate bottom-bar
/// tab.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canManage = ServerClient.instance.canManageShop;
    final isOwner = ServerClient.instance.isOwner;

    final items = <(IconData, String, WidgetBuilder)>[
      if (canManage)
        (Icons.restaurant_menu_outlined, l10n.menuLabel, (_) => const MenuManagementScreen()),
      if (canManage)
        (Icons.bar_chart_outlined, l10n.reportsLabel, (_) => const ReportsScreen()),
      if (isOwner)
        (Icons.people_outline, l10n.staffLabel, (_) => const StaffManagementScreen()),
      (Icons.settings_outlined, l10n.settingsLabel, (_) => const SettingsScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mobileBottomNavMore),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: const MobileNewOrderFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const MobileBottomNav(current: MobileTab.more),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final (icon, label, builder) = items[i];
          return Card(
            child: ListTile(
              leading: Icon(icon, color: AppColors.primary),
              title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: builder)),
            ),
          );
        },
      ),
    );
  }
}
