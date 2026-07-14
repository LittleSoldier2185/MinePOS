import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../cashier/order_history_screen.dart';
import '../cashier/order_taking_screen.dart';
import '../kitchen/kitchen_display_screen.dart';
import 'more_screen.dart';

/// Which mobile screen currently owns [MobileBottomNav] — used only to
/// disable that one tab's own tap (matches the existing "tapping Home while
/// already on Home does nothing" behavior), not for any active-tab styling;
/// there isn't a selected-state look elsewhere in this bar either.
enum MobileTab { home, orders, kitchen, more }

/// Bottom nav + centered "New Order" FAB notch, shared by every mobile
/// screen a cashier is likely to want quick order-taking access from — not
/// just the hub, since jumping back to Home first just to start a new order
/// is exactly the friction this is meant to remove. Each screen wires this
/// in via its own `Scaffold`'s `bottomNavigationBar`, gated to
/// `Responsive.isMobile(context)` (and, for Kitchen, to `!standalone` too —
/// a standalone kitchen-only station has no hub to navigate to).
class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({super.key, required this.current});
  final MobileTab current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = <(MobileTab, IconData, String, VoidCallback)>[
      (
        MobileTab.home,
        Icons.home_outlined,
        l10n.mobileBottomNavHome,
        // Home is the root of this stack, never pushed directly elsewhere,
        // so "go home" means unwind back to it rather than push a new copy.
        () => Navigator.of(context).popUntil((route) => route.isFirst),
      ),
      (
        MobileTab.orders,
        Icons.receipt_long_outlined,
        l10n.mobileBottomNavOrders,
        () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
      ),
      (
        MobileTab.kitchen,
        Icons.soup_kitchen_outlined,
        l10n.kitchenNavLabel,
        () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const KitchenDisplayScreen())),
      ),
      (
        MobileTab.more,
        Icons.more_horiz,
        l10n.mobileBottomNavMore,
        () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const MoreScreen())),
      ),
    ];
    final mid = (entries.length / 2).ceil();

    Widget navButton((MobileTab, IconData, String, VoidCallback) e) => Expanded(
      child: InkWell(
        onTap: e.$1 == current ? null : e.$4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(e.$2, color: AppColors.muted),
            const SizedBox(height: 2),
            Text(e.$3, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      ),
    );

    // Deliberately a plain Material, not BottomAppBar: BottomAppBar always
    // wires a _BottomAppBarClipper into its PhysicalShape — even with no
    // `shape:` set, Material 3's theme defaults one in — and
    // RenderPhysicalShape.hitTest() invokes that clipper on every hit test
    // whenever a clipper exists at all (independent of clipBehavior). The
    // clipper reads Scaffold.geometryOf(), which is only valid during
    // paint, so desktop/web mouse-hover hit-testing (which runs outside
    // paint) throws "must only be accessed during the paint phase" on every
    // hover — unavoidable with BottomAppBar itself, not just its notch
    // option. A plain Material's elevation shadow doesn't depend on scaffold
    // geometry, so it doesn't have this problem. The FAB still centers fine
    // via floatingActionButtonLocation.centerDocked without a cutout.
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              ...entries.take(mid).map(navButton),
              const Spacer(),
              ...entries.skip(mid).map(navButton),
            ],
          ),
        ),
      ),
    );
  }
}

/// The centered "New Order" FAB that docks into [MobileBottomNav]'s notch.
class MobileNewOrderFab extends StatelessWidget {
  const MobileNewOrderFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const OrderTakingScreen())),
      tooltip: AppLocalizations.of(context)!.newOrderButton,
      child: const Icon(Icons.add),
    );
  }
}
