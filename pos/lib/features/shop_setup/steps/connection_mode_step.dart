import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/window/platform_window.dart';
import '../models/shop_setup_data.dart';

class ConnectionModeStep extends StatefulWidget {
  const ConnectionModeStep({super.key, required this.data});

  final ShopSetupData data;

  @override
  State<ConnectionModeStep> createState() => _ConnectionModeStepState();
}

class _ConnectionModeStepState extends State<ConnectionModeStep> {
  @override
  void initState() {
    super.initState();
    // Self-hosting requires a Windows desktop host; force Cloud everywhere else.
    if (!isWindowsDesktop) {
      widget.data.connectionMode = ConnectionMode.cloud;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Connection mode', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'How will this shop run?',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
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
            title: const Text('Local (this device)'),
            subtitle: Text(
              isWindowsDesktop
                  ? 'Self-host on this Windows PC. Other devices connect over Wi-Fi.'
                  : 'Only available on the Windows desktop app.',
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
            title: const Text('Cloud'),
            subtitle: const Text('Host online instead of on a local device.'),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
