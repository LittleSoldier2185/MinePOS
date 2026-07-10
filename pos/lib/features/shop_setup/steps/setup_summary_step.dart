import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../models/shop_setup_data.dart';

class SetupSummaryStep extends StatelessWidget {
  const SetupSummaryStep({super.key, required this.data});

  final ShopSetupData data;

  String _connectionLabel(AppLocalizations l10n) => data.connectionMode == ConnectionMode.local
      ? l10n.connectionModeLocalLabel
      : l10n.connectionModeCloudLabel;

  String _printerLabel(AppLocalizations l10n) {
    switch (data.printerChoice) {
      case PrinterChoice.bluetooth:
        return l10n.bluetooth;
      case PrinterChoice.usb:
        return l10n.usb;
      case PrinterChoice.skip:
        return l10n.summaryPrinterSkippedLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.setupSummaryStepTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            l10n.setupSummaryStepSubtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (data.logoBytes != null)
            Center(
              child: CircleAvatar(radius: 40, backgroundImage: MemoryImage(data.logoBytes!)),
            ),
          const SizedBox(height: 12),
          _SummaryRow(label: l10n.shopNameFieldLabel, value: data.shopName),
          _SummaryRow(label: l10n.emailFieldLabel, value: data.email),
          if (data.address.isNotEmpty) _SummaryRow(label: l10n.addressFieldLabel, value: data.address),
          if (data.taxId.isNotEmpty) _SummaryRow(label: l10n.taxIdFieldLabel, value: data.taxId),
          if (data.receiptFooter.isNotEmpty)
            _SummaryRow(label: l10n.receiptFooterFieldLabel, value: data.receiptFooter),
          const Divider(height: 32),
          _SummaryRow(label: l10n.summaryRowLabelAdminUsername, value: data.adminUsername),
          const Divider(height: 32),
          _SummaryRow(label: l10n.summaryRowLabelConnectionMode, value: _connectionLabel(l10n)),
          if (data.connectionMode == ConnectionMode.cloud && data.cloudServerAddress.isNotEmpty)
            _SummaryRow(label: l10n.connectServerAddressLabel, value: data.cloudServerAddress),
          _SummaryRow(label: l10n.summaryRowLabelPrinter, value: _printerLabel(l10n)),
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
