import 'package:flutter/material.dart';

import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/window/platform_window.dart';
import '../auth/login_screen.dart';
import 'models/discovered_host.dart';
import 'services/connection_service.dart';
import 'services/mdns_discovery_service.dart';

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
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _connect(String address) async {
    if (address.trim().isEmpty) {
      setState(() => _connectError = 'Enter a server address');
      return;
    }

    setState(() {
      _connecting = true;
      _connectError = null;
    });

    final success = await _connectionService.testConnection(address);

    if (!mounted) return;
    setState(() => _connecting = false);

    if (success) {
      ServerClient.instance.baseUrl = address.trim();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LoginScreen(serverAddress: address.trim())),
      );
    } else {
      setState(() => _connectError = "Couldn't connect. Check the address and try again.");
    }
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
        appBar: AppBar(title: const Text('Connect to Server')),
        body: manual,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Server'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'ON THIS WI-FI'), Tab(text: 'MANUAL')],
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
          Text('Enter server address', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Ask your admin for the address of the MinePOS host.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          if (showMixedContentNote) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.terracottaLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.terracottaDark),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Wi-Fi discovery isn\'t available in a web browser. If your host address '
                      'uses http:// and this page is loaded over https://, your browser may block '
                      'the connection as mixed content.',
                      style: TextStyle(fontSize: 12, color: AppColors.terracottaDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          AppTextField(
            label: 'Server Address',
            controller: addressController,
            hintText: '192.168.1.10:8080',
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
                  : const Text('CONNECT'),
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
  List<DiscoveredHost> _hosts = const [];

  Future<void> _scan() async {
    setState(() => _scanning = true);
    _discovery.hosts.listen((hosts) {
      if (mounted) setState(() => _hosts = hosts);
    });
    await _discovery.start();
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
          Text('Shops on this Wi-Fi', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Make sure this device is on the same Wi-Fi as the MinePOS host.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (!_scanning)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.wifi_find),
                label: const Text('SCAN FOR SHOPS'),
              ),
            )
          else ...[
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                SizedBox(width: 12),
                Text('Scanning...', style: TextStyle(color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 16),
            if (_hosts.isEmpty)
              const Text(
                'No shops found yet.',
                style: TextStyle(color: AppColors.muted, fontStyle: FontStyle.italic),
              )
            else
              ..._hosts.map(
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
