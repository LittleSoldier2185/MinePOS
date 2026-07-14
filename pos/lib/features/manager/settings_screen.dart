import 'package:flutter/material.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/services/locale_controller.dart';
import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/window/platform_window.dart';
import '../../l10n/app_localizations.dart';
import '../cashier/services/menu_service.dart';
import '../cashier/services/order_service.dart';
import '../cashier/services/printer_service.dart';
import '../welcome/welcome_screen.dart';
import 'server_status_screen.dart';
import 'services/shop_config_service.dart';
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
  String? _printerDeviceName;
  ReceiptPaperSize? _paperSize;

  final _shopFormKey = GlobalKey<FormState>();
  late final _shopNameController = TextEditingController();
  late final _shopAddressController = TextEditingController();
  late final _shopTaxIdController = TextEditingController();
  late final _shopEmailController = TextEditingController();
  late final _shopFooterController = TextEditingController();
  bool _shopLoaded = false;
  bool _savingShop = false;
  String? _shopError;

  @override
  void initState() {
    super.initState();
    _load();
    _loadShopDetails();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _shopTaxIdController.dispose();
    _shopEmailController.dispose();
    _shopFooterController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final printer = await _svc.getPrinterChoice();
    final language = await _svc.getLanguage();
    final deviceName = await _svc.getSelectedPrinterName();
    final paperSize = await _svc.getPaperSize();
    if (!mounted) return;
    setState(() {
      _printer = printer;
      _language = language;
      _printerDeviceName = deviceName;
      _paperSize = paperSize;
    });
  }

  Future<void> _loadShopDetails() async {
    if (!ServerClient.instance.canManageShop) return;
    await ShopConfigService.instance.fetch();
    if (!mounted) return;
    final shop = ShopConfigService.instance;
    setState(() {
      _shopNameController.text = shop.shopName;
      _shopAddressController.text = shop.address ?? '';
      _shopTaxIdController.text = shop.taxId ?? '';
      _shopEmailController.text = shop.email ?? '';
      _shopFooterController.text = shop.receiptFooter ?? '';
      _shopLoaded = true;
    });
  }

  Future<void> _saveShopDetails() async {
    if (!(_shopFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _savingShop = true;
      _shopError = null;
    });
    try {
      await ShopConfigService.instance.update(
        shopName: _shopNameController.text,
        address: _shopAddressController.text,
        taxId: _shopTaxIdController.text,
        email: _shopEmailController.text,
        receiptFooter: _shopFooterController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.shopDetailsSavedMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _shopError = '$e');
    } finally {
      if (mounted) setState(() => _savingShop = false);
    }
  }

  Future<void> _setPrinter(PrinterChoice choice) async {
    setState(() => _printer = choice);
    await _svc.setPrinterChoice(choice);
    if (choice == PrinterChoice.skip) {
      await _svc.clearSelectedPrinter();
      if (mounted) setState(() => _printerDeviceName = null);
    }
  }

  Future<void> _setPaperSize(ReceiptPaperSize size) async {
    setState(() => _paperSize = size);
    await _svc.setPaperSize(size);
  }

  Future<void> _selectPrinterDevice() async {
    final chosen = await showDialog<PrinterDevice>(
      context: context,
      builder: (_) => _PrinterPickerDialog(choice: _printer!),
    );
    if (chosen == null) return;
    await _svc.setSelectedPrinter(
      id: printerDeviceKey(chosen),
      name: chosen.name,
    );
    if (mounted) setState(() => _printerDeviceName = chosen.name);
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
            child: Text(
              l10n.disconnectLabel,
              style: const TextStyle(color: AppColors.terracottaDark),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      MenuService.instance.reset();
      OrderService.instance.reset();
      ShopConfigService.instance.reset();
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
      // Barrier tap / drag are disabled so an accidental tap or swipe can't
      // dismiss this mid-delete — see PopScope in _RemoveShopSheet, which
      // additionally blocks the back button while the delete is in flight.
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const _RemoveShopSheet(),
    );
    if (deleted == true && mounted) {
      MenuService.instance.reset();
      OrderService.instance.reset();
      ShopConfigService.instance.reset();
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
      body: (_printer == null || _language == null || _paperSize == null)
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SectionLabel(l10n.settingsAccountSectionLabel),
                    _Card(
                      child: Column(
                        children: [
                          _InfoRow(
                            label: l10n.signedInAsLabel,
                            value: client.username ?? l10n.emDash,
                          ),
                          const Divider(height: 20),
                          _InfoRow(
                            label: l10n.roleLabel,
                            value:
                                (client.role == 'worker'
                                        ? l10n.employeeRoleDisplay
                                        : (client.role == 'manager'
                                              ? l10n.managerRoleDisplay
                                              : l10n.ownerRoleDisplay))
                                    .toUpperCase(),
                          ),
                        ],
                      ),
                    ),
                    if (client.canManageShop && _shopLoaded) ...[
                      const SizedBox(height: 20),
                      _SectionLabel(l10n.shopDetailsSectionLabel),
                      _Card(
                        child: Form(
                          key: _shopFormKey,
                          child: Column(
                            children: [
                              AppTextField(
                                label: l10n.shopNameFieldLabel,
                                controller: _shopNameController,
                                hintText: l10n.shopNameFieldHint,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? l10n.shopNameValidatorError
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                label: l10n.emailFieldLabel,
                                controller: _shopEmailController,
                                hintText: l10n.emailFieldHint,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                label: l10n.addressFieldLabel,
                                controller: _shopAddressController,
                                hintText: l10n.optionalHint,
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                label: l10n.taxIdFieldLabel,
                                controller: _shopTaxIdController,
                                hintText: l10n.optionalHint,
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                label: l10n.receiptFooterFieldLabel,
                                controller: _shopFooterController,
                                hintText: l10n.receiptFooterFieldHint,
                              ),
                              if (_shopError != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _shopError!,
                                  style: const TextStyle(
                                    color: AppColors.terracottaDark,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _savingShop ? null : _saveShopDetails,
                                  child: _savingShop
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(l10n.saveChangesButton),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _SectionLabel(l10n.connectionSectionLabel),
                    _Card(
                      child: Column(
                        children: [
                          _InfoRow(
                            label: l10n.settingsServerAddressLabel,
                            value: client.baseUrl ?? l10n.emDash,
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _disconnect,
                              icon: const Icon(Icons.link_off, size: 16),
                              label: Text(l10n.disconnectLabel),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.terracottaDark,
                                side: const BorderSide(
                                  color: AppColors.terracottaDark,
                                ),
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
                          if (_printer != PrinterChoice.skip) ...[
                            const Divider(height: 24),
                            _InfoRow(
                              label: l10n.selectedPrinterLabel,
                              value:
                                  _printerDeviceName ??
                                  l10n.printerNotSelectedValue,
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _selectPrinterDevice,
                                icon: const Icon(Icons.search, size: 16),
                                label: Text(
                                  _printerDeviceName == null
                                      ? l10n.selectPrinterButton
                                      : l10n.changePrinterButton,
                                ),
                              ),
                            ),
                            const Divider(height: 24),
                            Text(
                              l10n.paperSizeLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _ChoiceRow(
                                    icon: Icons.receipt_long,
                                    label: l10n.paperSize58,
                                    selected:
                                        _paperSize == ReceiptPaperSize.mm58,
                                    onTap: () =>
                                        _setPaperSize(ReceiptPaperSize.mm58),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _ChoiceRow(
                                    icon: Icons.receipt_long,
                                    label: l10n.paperSize80,
                                    selected:
                                        _paperSize == ReceiptPaperSize.mm80,
                                    onTap: () =>
                                        _setPaperSize(ReceiptPaperSize.mm80),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            l10n.printerDiscoveryNote,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
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
                    if (client.isOwner &&
                        isWindowsDesktop &&
                        (client.baseUrl?.startsWith('127.0.0.1') ?? false)) ...[
                      const SizedBox(height: 20),
                      _SectionLabel(l10n.serverSectionLabel),
                      _Card(
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ServerStatusScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.dns_outlined, size: 16),
                            label: Text(l10n.serverStatusButton),
                          ),
                        ),
                      ),
                    ],
                    if (client.isOwner) ...[
                      const SizedBox(height: 20),
                      _SectionLabel(l10n.dangerZoneSectionLabel),
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.removeShopWarningText,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _removeShop,
                                icon: const Icon(
                                  Icons.delete_forever,
                                  size: 16,
                                ),
                                label: Text(l10n.removeShopButton),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.terracottaDark,
                                  side: const BorderSide(
                                    color: AppColors.terracottaDark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
    // Blocks the back button while the delete is in flight, so it can't be
    // used to slip past the disabled Cancel/Confirm buttons — the barrier
    // tap and drag-to-dismiss routes are already closed off via
    // isDismissible/enableDrag on the showModalBottomSheet call that opens
    // this sheet.
    return PopScope(
      canPop: !_deleting,
      child: Container(
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
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.removeShopDialogWarning,
                style: const TextStyle(
                  color: AppColors.terracottaDark,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: l10n.emailFieldLabel,
                controller: _emailController,
                hintText: l10n.removeShopEmailHint,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.emailRequiredValidatorError
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: l10n.usernameLabel,
                controller: _usernameController,
                hintText: ServerClient.instance.username,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.usernameRequiredValidator
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: l10n.passwordLabel,
                controller: _passwordController,
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty)
                    ? l10n.passwordRequiredValidator
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.terracottaDark,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _deleting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _deleting ? null : _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracottaDark,
                      ),
                      child: _deleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
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
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: AppColors.muted,
        ),
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
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
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
          color: selected
              ? AppColors.terracottaLight.withValues(alpha: 0.4)
              : AppColors.background,
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
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _PrinterPickerDialog extends StatefulWidget {
  const _PrinterPickerDialog({required this.choice});
  final PrinterChoice choice;

  @override
  State<_PrinterPickerDialog> createState() => _PrinterPickerDialogState();
}

class _PrinterPickerDialogState extends State<_PrinterPickerDialog> {
  late Future<List<PrinterDevice>> _future = PrinterService().scanAvailable(
    widget.choice,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.selectPrinterDialogTitle),
      content: SizedBox(
        width: 320,
        child: FutureBuilder<List<PrinterDevice>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.scanningForPrintersLabel,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              );
            }
            final devices = snapshot.data ?? const [];
            if (devices.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.noPrintersFoundMessage,
                  style: const TextStyle(color: AppColors.muted),
                ),
              );
            }
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: devices.length,
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(
                    Icons.print_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(devices[i].name),
                  onTap: () => Navigator.of(context).pop(devices[i]),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(
            () => _future = PrinterService().scanAvailable(widget.choice),
          ),
          child: Text(l10n.retry),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
