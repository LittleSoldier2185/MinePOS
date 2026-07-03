import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Printer setup', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Choose how receipts will print. You can change this later.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _PrinterOption(
            icon: Icons.bluetooth,
            title: 'Bluetooth',
            subtitle: 'Pair a Bluetooth thermal printer',
            selected: widget.data.printerChoice == PrinterChoice.bluetooth,
            onTap: () => _select(PrinterChoice.bluetooth),
          ),
          const SizedBox(height: 12),
          _PrinterOption(
            icon: Icons.usb,
            title: 'USB',
            subtitle: 'Connect a USB thermal printer',
            selected: widget.data.printerChoice == PrinterChoice.usb,
            onTap: () => _select(PrinterChoice.usb),
          ),
          const SizedBox(height: 12),
          _PrinterOption(
            icon: Icons.skip_next,
            title: 'Skip for now',
            subtitle: 'Set up a printer later from Settings',
            selected: widget.data.printerChoice == PrinterChoice.skip,
            onTap: () => _select(PrinterChoice.skip),
          ),
          const SizedBox(height: 16),
          const Text(
            'Printer discovery is coming soon — this just records your preference for now.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, fontStyle: FontStyle.italic),
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
