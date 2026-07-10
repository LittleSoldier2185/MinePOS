import 'package:flutter/material.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/services/locale_controller.dart';
import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../l10n/app_localizations.dart';
import '../welcome/welcome_screen.dart';
import 'services/shop_service.dart';

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
    LocaleController.instance.setLanguage(language);
  }

  Future<void> _disconnect() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.disconnectTitle),
        content: Text(l10n.disconnectContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.disconnectLabel,
                style: const TextStyle(color: AppColors.terracottaDark)),
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

  Future<void> _removeShop() async {
    final deleted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RemoveShopSheet(),
    );
    if (deleted == true && mounted) {
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsLabel),
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
                _SectionLabel(l10n.settingsAccountSectionLabel),
                _Card(
                  child: Column(
                    children: [
                      _InfoRow(label: l10n.signedInAsLabel, value: client.username ?? l10n.emDash),
                      const Divider(height: 20),
                      _InfoRow(
                        label: l10n.roleLabel,
                        value: (client.role == 'worker'
                                ? l10n.employeeRoleDisplay
                                : (client.role == 'manager'
                                    ? l10n.managerRoleDisplay
                                    : l10n.ownerRoleDisplay))
                            .toUpperCase(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionLabel(l10n.connectionSectionLabel),
                _Card(
                  child: Column(
                    children: [
                      _InfoRow(label: l10n.settingsServerAddressLabel, value: client.baseUrl ?? l10n.emDash),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _disconnect,
                          icon: const Icon(Icons.link_off, size: 16),
                          label: Text(l10n.disconnectLabel),
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
                _SectionLabel(l10n.printerSectionLabel),
                _Card(
                  child: Column(
                    children: [
                      _ChoiceRow(
                        icon: Icons.bluetooth,
                        label: l10n.bluetooth,
                        selected: _printer == PrinterChoice.bluetooth,
                        onTap: () => _setPrinter(PrinterChoice.bluetooth),
                      ),
                      const SizedBox(height: 8),
                      _ChoiceRow(
                        icon: Icons.usb,
                        label: l10n.usb,
                        selected: _printer == PrinterChoice.usb,
                        onTap: () => _setPrinter(PrinterChoice.usb),
                      ),
                      const SizedBox(height: 8),
                      _ChoiceRow(
                        icon: Icons.block,
                        label: l10n.noPrinterOption,
                        selected: _printer == PrinterChoice.skip,
                        onTap: () => _setPrinter(PrinterChoice.skip),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.printerDiscoveryNote,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionLabel(l10n.languageSectionLabel),
                _Card(
                  child: Column(
                    children: [
                      _ChoiceRow(
                        icon: Icons.language,
                        label: l10n.englishOption,
                        selected: _language == AppLanguage.english,
                        onTap: () => _setLanguage(AppLanguage.english),
                      ),
                      const SizedBox(height: 8),
                      _ChoiceRow(
                        icon: Icons.language,
                        label: l10n.thaiOption,
                        selected: _language == AppLanguage.thai,
                        onTap: () => _setLanguage(AppLanguage.thai),
                      ),
                    ],
                  ),
                ),
                if (client.isOwner) ...[
                  const SizedBox(height: 20),
                  _SectionLabel(l10n.dangerZoneSectionLabel),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.removeShopWarningText,
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _removeShop,
                            icon: const Icon(Icons.delete_forever, size: 16),
                            label: Text(l10n.removeShopButton),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.terracottaDark,
                              side: const BorderSide(color: AppColors.terracottaDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _RemoveShopSheet extends StatefulWidget {
  const _RemoveShopSheet();

  @override
  State<_RemoveShopSheet> createState() => _RemoveShopSheetState();
}

class _RemoveShopSheetState extends State<_RemoveShopSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _deleting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ShopService.instance.deleteShop(
        email: _emailController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.terracottaLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.removeShopDialogTitle,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.removeShopDialogWarning,
                style: const TextStyle(color: AppColors.terracottaDark, fontSize: 12),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: l10n.emailFieldLabel,
                controller: _emailController,
                hintText: l10n.removeShopEmailHint,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.emailRequiredValidatorError : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: l10n.usernameLabel,
                controller: _usernameController,
                hintText: ServerClient.instance.username,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.usernameRequiredValidator : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: l10n.passwordLabel,
                controller: _passwordController,
                obscureText: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? l10n.passwordRequiredValidator : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.terracottaDark, fontSize: 12)),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _deleting ? null : () => Navigator.of(context).pop(false),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _deleting ? null : _confirm,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracottaDark),
                      child: _deleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l10n.removeShopConfirmButton),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
