import 'package:flutter/material.dart';

import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../cashier/models/order_item.dart';
import '../cashier/services/menu_service.dart';
import '../cashier/services/order_service.dart';
import '../manager/services/shop_config_service.dart';
import '../welcome/welcome_screen.dart';
import 'services/customer_display_service.dart';

/// Full-screen, kiosk-style view meant for a second monitor/device facing
/// the customer. Purely passive — it never calls the server directly,
/// it just mirrors whatever the cashier's register publishes over
/// `/ws/customer-display`.
class CustomerDisplayScreen extends StatefulWidget {
  const CustomerDisplayScreen({super.key});

  @override
  State<CustomerDisplayScreen> createState() => _CustomerDisplayScreenState();
}

class _CustomerDisplayScreenState extends State<CustomerDisplayScreen> {
  final _svc = CustomerDisplayService.instance;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onChange);
    _svc.connect();
  }

  @override
  void dispose() {
    _svc.removeListener(_onChange);
    _svc.disconnect();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmExit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.exitCustomerDisplayTitle),
        content:
            Text(AppLocalizations.of(context)!.exitCustomerDisplayContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.exitButton),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      MenuService.instance.reset();
      OrderService.instance.reset();
      ShopConfigService.instance.reset();
      ServerClient.instance.clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  String _baht(double v) => '฿${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildBody()),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white24, size: 20),
                onPressed: _confirmExit,
              ),
            ),
            Positioned(
              top: 12,
              right: 16,
              child: _ConnectionDot(state: _svc.connectionState),
            ),
            if (_svc.selectedStation != null)
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _svc.selectStation(null),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tv_outlined, size: 12, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(_svc.selectedStation!,
                            style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_svc.selectedStation == null) {
      return _StationPickerView(svc: _svc);
    }
    switch (_svc.state) {
      case CustomerDisplayState.cart:
        return _CartView(svc: _svc, baht: _baht);
      case CustomerDisplayState.thankYou:
        return _ThankYouView(svc: _svc, baht: _baht);
      case CustomerDisplayState.idle:
        return const _IdleView();
    }
  }
}

class _StationPickerView extends StatelessWidget {
  const _StationPickerView({required this.svc});
  final CustomerDisplayService svc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tv_outlined, color: AppColors.primaryLight, size: 56),
            const SizedBox(height: 20),
            Text(
              l10n.selectStationTitle,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            if (svc.stations.isEmpty)
              Text(
                l10n.noStationsOnlineMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              )
            else
              ...svc.stations.map(
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SizedBox(
                    width: 260,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => svc.selectStation(s),
                      child: Text(s, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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

class _IdleView extends StatelessWidget {
  const _IdleView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_cafe, color: AppColors.accent, size: 44),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.welcomeToMinePosMessage,
            style: const TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.orderWillAppearMessage,
            style: const TextStyle(color: Colors.white54, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _CartView extends StatelessWidget {
  const _CartView({required this.svc, required this.baht});
  final CustomerDisplayService svc;
  final String Function(double) baht;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 40, 32, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                svc.orderNumber.isEmpty
                    ? AppLocalizations.of(context)!.customerDisplayOrderLabel
                    : AppLocalizations.of(context)!
                        .customerDisplayOrderWithNumber(svc.orderNumber),
                style: const TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
              Text(
                AppLocalizations.of(context)!.itemsCount(
                    svc.items.fold<int>(0, (s, i) => s + i.quantity)),
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            itemCount: svc.items.length,
            separatorBuilder: (_, _) => const Divider(color: Colors.white12, height: 1),
            itemBuilder: (context, index) {
              final item = svc.items[index];
              final name = item.menuItem.displayName(Localizations.localeOf(context));
              final label = item.sweetness == null
                  ? name
                  : '$name (${item.sweetness!.label(AppLocalizations.of(context)!)})';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Text('${item.quantity}×',
                        style: const TextStyle(color: Colors.white54, fontSize: 18)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(label,
                          style: const TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                    Text(baht(item.subtotal),
                        style: const TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.total,
                  style: const TextStyle(color: Colors.white70, fontSize: 20)),
              Text(
                baht(svc.total),
                style: const TextStyle(
                    color: AppColors.primaryLight, fontSize: 34, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThankYouView extends StatelessWidget {
  const _ThankYouView({required this.svc, required this.baht});
  final CustomerDisplayService svc;
  final String Function(double) baht;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.primaryLight, size: 84),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.thankYouMessage,
            style: const TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
              AppLocalizations.of(context)!
                  .totalPaidLabel(baht(svc.thankYouTotal)),
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          if (svc.thankYouChange > 0) ...[
            const SizedBox(height: 4),
            Text(
                AppLocalizations.of(context)!
                    .changeMessageLabel(baht(svc.thankYouChange)),
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ],
      ),
    );
  }
}

class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot({required this.state});
  final CustomerDisplayConnectionState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      CustomerDisplayConnectionState.connected => Colors.green,
      CustomerDisplayConnectionState.connecting => Colors.amber,
      CustomerDisplayConnectionState.error => AppColors.terracottaDark,
      CustomerDisplayConnectionState.disconnected => Colors.white24,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
