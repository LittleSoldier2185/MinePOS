import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/window/platform_window.dart';
import '../../../l10n/app_localizations.dart';
import '../../connect/models/discovered_host.dart';
import '../../connect/services/mdns_discovery_service.dart';
import '../models/shop_setup_data.dart';

class ConnectionModeStep extends StatefulWidget {
  const ConnectionModeStep({super.key, required this.formKey, required this.data});

  final GlobalKey<FormState> formKey;
  final ShopSetupData data;

  @override
  State<ConnectionModeStep> createState() => _ConnectionModeStepState();
}

class _ConnectionModeStepState extends State<ConnectionModeStep> {
  late final _addressController = TextEditingController(text: widget.data.cloudServerAddress);
  final _discovery = MdnsDiscoveryService();
  bool _scanning = false;
  List<DiscoveredHost> _hosts = const [];

  @override
  void initState() {
    super.initState();
    // Self-hosting requires a Windows desktop host; force Cloud everywhere else.
    if (!isWindowsDesktop) {
      widget.data.connectionMode = ConnectionMode.cloud;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _discovery.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    _discovery.hosts.listen((hosts) {
      if (mounted) setState(() => _hosts = hosts);
    });
    await _discovery.start();
  }

  void _selectHost(DiscoveredHost host) {
    setState(() {
      _addressController.text = host.displayAddress;
      widget.data.cloudServerAddress = host.displayAddress;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.connectionModeStepTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              l10n.connectionModeStepSubtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            // RadioListTile's groupValue/onChanged (vs. wrapping in a RadioGroup)
            // is deprecated but still functional; kept because RadioGroup has no
            // clean way to disable a single item, which "Local" needs on non-Windows.
            // ignore: deprecated_member_use
            RadioListTile<ConnectionMode>(
              value: ConnectionMode.local,
              // ignore: deprecated_member_use
              groupValue: widget.data.connectionMode,
              // ignore: deprecated_member_use
              onChanged: isWindowsDesktop
                  ? (value) => setState(() => widget.data.connectionMode = value!)
                  : null,
              title: Text(l10n.connectionModeLocalLabel),
              subtitle: Text(
                isWindowsDesktop
                    ? l10n.localConnectionModeSubtitleWindows
                    : l10n.localConnectionModeSubtitleOther,
              ),
              activeColor: AppColors.primary,
            ),
            // ignore: deprecated_member_use
            RadioListTile<ConnectionMode>(
              value: ConnectionMode.cloud,
              // ignore: deprecated_member_use
              groupValue: widget.data.connectionMode,
              // ignore: deprecated_member_use
              onChanged: (value) => setState(() => widget.data.connectionMode = value!),
              title: Text(l10n.connectionModeCloudLabel),
              subtitle: Text(l10n.cloudConnectionModeSubtitle),
              activeColor: AppColors.primary,
            ),
            if (widget.data.connectionMode == ConnectionMode.cloud) ...[
              const SizedBox(height: 8),
              AppTextField(
                label: l10n.connectServerAddressLabel,
                controller: _addressController,
                hintText: l10n.connectServerAddressHint,
                onChanged: (value) => widget.data.cloudServerAddress = value,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? l10n.connectEmptyAddressError : null,
              ),
              if (supportsMdns) ...[
                const SizedBox(height: 16),
                if (!_scanning)
                  OutlinedButton.icon(
                    onPressed: _scan,
                    icon: const Icon(Icons.wifi_find),
                    label: Text(l10n.connectScanButton),
                  )
                else ...[
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Text(l10n.connectScanningLabel, style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_hosts.isEmpty)
                    Text(
                      l10n.connectNoShopsFound,
                      style: const TextStyle(color: AppColors.muted, fontStyle: FontStyle.italic),
                    )
                  else
                    ..._hosts.map(
                      (host) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.storefront, color: AppColors.primary),
                          title: Text(host.name),
                          subtitle: Text(host.displayAddress),
                          onTap: () => _selectHost(host),
                        ),
                      ),
                    ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}
