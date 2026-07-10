import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../models/shop_setup_data.dart';

class PrinterSetupStep extends StatefulWidget {
  const PrinterSetupStep({super.key, required this.data});

  final ShopSetupData data;

  @override
  State<PrinterSetupStep> createState() => _PrinterSetupStepState();
}

class _PrinterSetupStepState extends State<PrinterSetupStep> {
  void _select(PrinterChoice choice) {
    setState(() => widget.data.printerChoice = choice);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.printerSetupStepTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            l10n.printerSetupStepSubtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _PrinterOption(
            icon: Icons.bluetooth,
            title: l10n.bluetooth,
            subtitle: l10n.bluetoothPrinterOptionSubtitle,
            selected: widget.data.printerChoice == PrinterChoice.bluetooth,
            onTap: () => _select(PrinterChoice.bluetooth),
          ),
          const SizedBox(height: 12),
          _PrinterOption(
            icon: Icons.usb,
            title: l10n.usb,
            subtitle: l10n.usbPrinterOptionSubtitle,
            selected: widget.data.printerChoice == PrinterChoice.usb,
            onTap: () => _select(PrinterChoice.usb),
          ),
          const SizedBox(height: 12),
          _PrinterOption(
            icon: Icons.skip_next,
            title: l10n.skipPrinterOptionTitle,
            subtitle: l10n.skipPrinterOptionSubtitle,
            selected: widget.data.printerChoice == PrinterChoice.skip,
            onTap: () => _select(PrinterChoice.skip),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.printerDiscoveryNote,
            style: const TextStyle(color: AppColors.muted, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _PrinterOption extends StatelessWidget {
  const _PrinterOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.terracottaLight.withValues(alpha: 0.4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.terracottaLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
