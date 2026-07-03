import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/shop_setup_data.dart';

class SetupSummaryStep extends StatelessWidget {
  const SetupSummaryStep({super.key, required this.data});

  final ShopSetupData data;

  String _connectionLabel() =>
      data.connectionMode == ConnectionMode.local ? 'Local (this device)' : 'Cloud';

  String _printerLabel() {
    switch (data.printerChoice) {
      case PrinterChoice.bluetooth:
        return 'Bluetooth';
      case PrinterChoice.usb:
        return 'USB';
      case PrinterChoice.skip:
        return 'Skipped for now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review & finish', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Check everything looks right before creating your shop.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (data.logoBytes != null)
            Center(
              child: CircleAvatar(radius: 40, backgroundImage: MemoryImage(data.logoBytes!)),
            ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Shop Name', value: data.shopName),
          _SummaryRow(label: 'Email', value: data.email),
          if (data.address.isNotEmpty) _SummaryRow(label: 'Address', value: data.address),
          if (data.taxId.isNotEmpty) _SummaryRow(label: 'Tax ID', value: data.taxId),
          if (data.receiptFooter.isNotEmpty)
            _SummaryRow(label: 'Receipt Footer', value: data.receiptFooter),
          const Divider(height: 32),
          _SummaryRow(label: 'Admin Username', value: data.adminUsername),
          const Divider(height: 32),
          _SummaryRow(label: 'Connection Mode', value: _connectionLabel()),
          _SummaryRow(label: 'Printer', value: _printerLabel()),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
