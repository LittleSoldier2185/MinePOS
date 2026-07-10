import 'package:flutter/material.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../welcome/welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _svc = AppSettingsService.instance;
  PrinterChoice? _printer;
  AppLanguage? _language;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final printer = await _svc.getPrinterChoice();
    final language = await _svc.getLanguage();
    if (!mounted) return;
    setState(() {
      _printer = printer;
      _language = language;
    });
  }

  Future<void> _setPrinter(PrinterChoice choice) async {
    setState(() => _printer = choice);
    await _svc.setPrinterChoice(choice);
  }

  Future<void> _setLanguage(AppLanguage language) async {
    setState(() => _language = language);
    await _svc.setLanguage(language);
  }

  Future<void> _disconnect() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Disconnect from Server?'),
        content: const Text(
            'You will be signed out and returned to the welcome screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect',
                style: TextStyle(color: AppColors.terracottaDark)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ServerClient.instance.clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ServerClient.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: AppColors.background,
      body: (_printer == null || _language == null)
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _SectionLabel('ACCOUNT'),
                _Card(
                  child: Column(
                    children: [
                      _InfoRow(label: 'Signed in as', value: client.username ?? '—'),
                      const Divider(height: 20),
                      _InfoRow(
                        label: 'Role',
                        value: (client.role ?? 'worker').toUpperCase(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionLabel('CONNECTION'),
                _Card(
                  child: Column(
                    children: [
                      _InfoRow(label: 'Server address', value: client.baseUrl ?? '—'),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _disconnect,
                          icon: const Icon(Icons.link_off, size: 16),
                          label: const Text('Disconnect'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.terracottaDark,
                            side: const BorderSide(color: AppColors.terracottaDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionLabel('PRINTER'),
                _Card(
                  child: Column(
                    children: [
                      _ChoiceRow(
                        icon: Icons.bluetooth,
                        label: 'Bluetooth',
                        selected: _printer == PrinterChoice.bluetooth,
                        onTap: () => _setPrinter(PrinterChoice.bluetooth),
                      ),
                      const SizedBox(height: 8),
                      _ChoiceRow(
                        icon: Icons.usb,
                        label: 'USB',
                        selected: _printer == PrinterChoice.usb,
                        onTap: () => _setPrinter(PrinterChoice.usb),
                      ),
                      const SizedBox(height: 8),
                      _ChoiceRow(
                        icon: Icons.block,
                        label: 'None',
                        selected: _printer == PrinterChoice.skip,
                        onTap: () => _setPrinter(PrinterChoice.skip),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Printer discovery is coming soon — this just records your preference for now.',
                        style: TextStyle(
                            color: AppColors.muted, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionLabel('LANGUAGE'),
                _Card(
                  child: Column(
                    children: [
                      _ChoiceRow(
                        icon: Icons.language,
                        label: 'English',
                        selected: _language == AppLanguage.english,
                        onTap: () => _setLanguage(AppLanguage.english),
                      ),
                      const SizedBox(height: 8),
                      _ChoiceRow(
                        icon: Icons.language,
                        label: 'ภาษาไทย (Thai)',
                        selected: _language == AppLanguage.thai,
                        onTap: () => _setLanguage(AppLanguage.thai),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Full Thai translation is coming soon — this just records your preference for now.',
                        style: TextStyle(
                            color: AppColors.muted, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: AppColors.muted),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.terracottaLight),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.terracottaLight.withValues(alpha: 0.4) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
