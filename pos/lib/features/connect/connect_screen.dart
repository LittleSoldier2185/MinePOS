import 'package:flutter/material.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/window/platform_window.dart';
import '../../l10n/app_localizations.dart';
import '../role_select/role_selection_screen.dart';
import 'models/discovered_host.dart';
import 'services/connection_service.dart';
import 'services/lan_scan.dart';
import 'services/mdns_discovery_service.dart';

/// Entry point for joining an *existing* shop from a client device — asks
/// for the server address first, then (once confirmed reachable and already
/// set up) hands off to [RoleSelectionScreen] to pick what this device is
/// for. Deliberately address-first: unlike the old flow, there's no point
/// asking "what is this device for" before knowing there's even a shop to
/// join at that address.
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final _connectionService = ConnectionService();
  final _addressController = TextEditingController();
  bool _connecting = false;
  String? _connectError;

  @override
  void initState() {
    super.initState();
    if (supportsMdns) {
      _tabController = TabController(length: 2, vsync: this);
    }
    AppSettingsService.instance.getLastServerAddress().then((address) {
      if (mounted && address != null && _addressController.text.isEmpty) {
        setState(() => _addressController.text = address);
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _connect(String address) async {
    if (address.trim().isEmpty) {
      setState(() => _connectError = AppLocalizations.of(context)!.connectEmptyAddressError);
      return;
    }

    setState(() {
      _connecting = true;
      _connectError = null;
    });

    final status = await _connectionService.checkStatus(address);

    if (!mounted) return;
    setState(() => _connecting = false);

    if (!status.reachable) {
      setState(() => _connectError = AppLocalizations.of(context)!.connectFailureError);
      return;
    }
    if (!status.hasShop) {
      setState(() => _connectError = AppLocalizations.of(context)!.connectNoShopError);
      return;
    }

    ServerClient.instance.baseUrl = address.trim();
    AppSettingsService.instance.setLastServerAddress(address.trim());
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manual = _ManualConnectSection(
      addressController: _addressController,
      connecting: _connecting,
      error: _connectError,
      onConnect: () => _connect(_addressController.text),
      showMixedContentNote: !supportsMdns,
    );

    if (!supportsMdns) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.connectAppBarTitle)),
        body: manual,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.connectAppBarTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.connectTabWifi),
            Tab(text: AppLocalizations.of(context)!.connectTabManual),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WifiDiscoverySection(
            connecting: _connecting,
            onSelectHost: (host) => _connect(host.displayAddress),
          ),
          manual,
        ],
      ),
    );
  }
}

class _ManualConnectSection extends StatelessWidget {
  const _ManualConnectSection({
    required this.addressController,
    required this.connecting,
    required this.error,
    required this.onConnect,
    required this.showMixedContentNote,
  });

  final TextEditingController addressController;
  final bool connecting;
  final String? error;
  final VoidCallback onConnect;
  final bool showMixedContentNote;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.connectManualTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.connectManualInstructions,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          if (showMixedContentNote) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.terracottaLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.terracottaDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.connectMixedContentWarning,
                      style: const TextStyle(fontSize: 12, color: AppColors.terracottaDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          AppTextField(
            label: AppLocalizations.of(context)!.connectServerAddressLabel,
            controller: addressController,
            hintText: AppLocalizations.of(context)!.connectServerAddressHint,
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: AppColors.terracottaDark, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: connecting ? null : onConnect,
              child: connecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                    )
                  : Text(AppLocalizations.of(context)!.connectButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _WifiDiscoverySection extends StatefulWidget {
  const _WifiDiscoverySection({required this.connecting, required this.onSelectHost});

  final bool connecting;
  final void Function(DiscoveredHost host) onSelectHost;

  @override
  State<_WifiDiscoverySection> createState() => _WifiDiscoverySectionState();
}

class _WifiDiscoverySectionState extends State<_WifiDiscoverySection> {
  final _discovery = MdnsDiscoveryService();
  bool _scanning = false;
  bool _sweeping = false;
  int _sweepDone = 0;
  int _sweepTotal = 0;

  // Keyed by "address:port" so an mDNS hit and a subnet-sweep hit for the
  // same server collapse into one row.
  final Map<String, DiscoveredHost> _hosts = {};

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _sweeping = true;
      _sweepDone = 0;
      _sweepTotal = 0;
      _hosts.clear();
    });

    // mDNS — instant when the network actually forwards multicast. Skipped on
    // Windows/Linux, where bonsoir's browser is buggy (off-thread channel
    // callbacks) and the sweep below covers the same ground.
    if (supportsMdnsBrowse) {
      _discovery.hosts.listen((hosts) {
        if (!mounted) return;
        setState(() {
          for (final h in hosts) {
            _hosts[h.displayAddress] = h;
          }
        });
      });
      await _discovery.start();
    }

    // Subnet sweep — the LAN fallback for when mDNS is firewalled/blocked.
    final swept = await sweepLan(
      onProgress: (done, total) {
        if (!mounted) return;
        setState(() {
          _sweepDone = done;
          _sweepTotal = total;
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _sweeping = false;
      for (final h in swept) {
        _hosts.putIfAbsent(h.displayAddress, () => h);
      }
    });
  }

  @override
  void dispose() {
    _discovery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.connectWifiTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.connectWifiInstructions,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (!_scanning)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.wifi_find),
                label: Text(AppLocalizations.of(context)!.connectScanButton),
              ),
            )
          else ...[
            if (_sweeping)
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _sweepTotal == 0
                        ? AppLocalizations.of(context)!.connectScanningLabel
                        : '${AppLocalizations.of(context)!.connectScanningLabel}  $_sweepDone/$_sweepTotal',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              )
            else
              TextButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(AppLocalizations.of(context)!.connectScanButton),
              ),
            const SizedBox(height: 16),
            if (_hosts.isEmpty && !_sweeping)
              Text(
                AppLocalizations.of(context)!.connectNoShopsFound,
                style: const TextStyle(color: AppColors.muted, fontStyle: FontStyle.italic),
              )
            else
              ..._hosts.values.map(
                (host) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.storefront, color: AppColors.primary),
                    title: Text(host.name),
                    subtitle: Text(host.displayAddress),
                    onTap: widget.connecting ? null : () => widget.onSelectHost(host),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
