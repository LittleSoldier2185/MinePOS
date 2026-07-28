import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/services/extra_display_launcher.dart';
import '../../core/services/local_server_launcher.dart';
import '../../core/services/locale_controller.dart';
import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/window/platform_window.dart';
import '../../l10n/app_localizations.dart';
import '../cashier/services/menu_service.dart';
import '../cashier/services/order_service.dart';
import '../cashier/services/printer_service.dart';
import '../cashier/services/promptpay_qr.dart';
import '../welcome/welcome_screen.dart';
import 'promotion_editor_screen.dart';
import 'server_status_screen.dart';
import 'services/ad_service.dart';
import 'services/backup_service.dart';
import 'services/promotion_admin_service.dart';
import 'services/shop_config_service.dart';
import 'services/shop_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.embedded = false});

  /// True when shown inside a floating [Dialog] (desktop sidebar's gear
  /// icon) instead of pushed as a full page — drops the outer [Scaffold]/
  /// [AppBar] in favor of a compact title row with its own close button,
  /// since a [Dialog] has no app bar of its own. Same body/state either way.
  final bool embedded;

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
  late final _shopPromptPayController = TextEditingController();
  late final _shopPromptPayLabelController = TextEditingController();
  bool _shopLoaded = false;
  bool _savingShop = false;
  String? _shopError;
  bool _exportingBackup = false;
  bool _localServerRunning = false;

  List<AdSlideInfo> _adSlides = [];
  bool _adsLoaded = false;
  bool _uploadingAd = false;
  double _uploadProgress = 0;
  String? _adsError;
  final _adDurationControllers = <String, TextEditingController>{};

  List<Promotion> _promotions = [];
  bool _promotionsLoaded = false;
  String? _promotionsError;

  /// Which category is showing in the embedded (desktop dialog) two-pane
  /// layout — meaningless in full-page mode, where every section is just
  /// stacked in one scrolling list instead.
  int _selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadShopDetails();
    _checkLocalServer();
    _loadAds();
    _loadPromotions();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _shopTaxIdController.dispose();
    _shopEmailController.dispose();
    _shopFooterController.dispose();
    _shopPromptPayController.dispose();
    _shopPromptPayLabelController.dispose();
    for (final c in _adDurationControllers.values) {
      c.dispose();
    }
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
      _shopPromptPayController.text = shop.promptPayId ?? '';
      _shopPromptPayLabelController.text = shop.promptPayLabel ?? '';
      _shopLoaded = true;
    });
  }

  /// Whether this device itself is running a MinePOS server right now —
  /// checked live via loopback (see [LocalServerLauncher.isRunningLocally])
  /// rather than just looking at what address `ServerClient` happens to be
  /// connected through, so the Server section still shows up for an owner
  /// who reached their own host machine by its LAN IP instead of 127.0.0.1.
  Future<void> _checkLocalServer() async {
    if (!isWindowsDesktop || !ServerClient.instance.isOwner) return;
    final running = await LocalServerLauncher.instance.isRunningLocally();
    if (!mounted) return;
    setState(() => _localServerRunning = running);
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
        promptPayId: _shopPromptPayController.text,
        promptPayLabel: _shopPromptPayLabelController.text,
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

  Future<void> _loadAds() async {
    if (!ServerClient.instance.canManageShop) return;
    try {
      final slides = await AdService.instance.list();
      if (!mounted) return;
      setState(() {
        _adSlides = slides;
        _adsLoaded = true;
        for (final slide in slides) {
          _adDurationControllers.putIfAbsent(
            slide.id,
            () => TextEditingController(text: '${slide.durationSeconds ?? 8}'),
          );
        }
      });
    } catch (_) {
      // Left un-loaded — the section just won't render until this device
      // has a working connection, same as the shop-details section.
    }
  }

  Future<void> _pickAndUploadAd() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'webm', 'mov'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() {
      _uploadingAd = true;
      _uploadProgress = 0;
      _adsError = null;
    });
    try {
      final ext = path.split('.').last.toLowerCase();
      final bytes = await File(path).readAsBytes();
      await AdService.instance.upload(
        bytes,
        ext: ext,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      await _loadAds();
    } catch (e) {
      if (!mounted) return;
      setState(() => _adsError = '$e');
    } finally {
      if (mounted) setState(() => _uploadingAd = false);
    }
  }

  Future<void> _updateAdDuration(String id, String secondsText) async {
    final seconds = int.tryParse(secondsText);
    if (seconds == null || seconds <= 0) return;
    try {
      await AdService.instance.updateDuration(id, seconds);
    } catch (e) {
      if (!mounted) return;
      setState(() => _adsError = '$e');
    }
  }

  Future<void> _updateAdMuted(String id, bool muted) async {
    final index = _adSlides.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final previous = _adSlides[index];
    setState(() {
      _adSlides = List.of(_adSlides)
        ..[index] = AdSlideInfo(
          id: previous.id,
          type: previous.type,
          url: previous.url,
          durationSeconds: previous.durationSeconds,
          muted: muted,
        );
    });
    try {
      await AdService.instance.updateMuted(id, muted);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _adsError = '$e';
        _adSlides = List.of(_adSlides)..[index] = previous;
      });
    }
  }

  Future<void> _deleteAdSlide(String id) async {
    try {
      await AdService.instance.delete(id);
      _adDurationControllers.remove(id)?.dispose();
      await _loadAds();
    } catch (e) {
      if (!mounted) return;
      setState(() => _adsError = '$e');
    }
  }

  Future<void> _reorderAdSlide(int oldIndex, int newIndex) async {
    final reordered = List<AdSlideInfo>.from(_adSlides);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    setState(() => _adSlides = reordered);
    try {
      await AdService.instance.reorder(reordered.map((s) => s.id).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => _adsError = '$e');
      await _loadAds();
    }
  }

  Future<void> _loadPromotions() async {
    if (!ServerClient.instance.canManageShop) return;
    try {
      final promotions = await PromotionAdminService.instance.list();
      if (!mounted) return;
      setState(() {
        _promotions = promotions;
        _promotionsLoaded = true;
      });
    } catch (_) {
      // Left un-loaded — same reasoning as _loadAds: the section just
      // won't render until this device has a working connection.
    }
  }

  Future<void> _openPromotionEditor({Promotion? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PromotionEditorScreen(existing: existing)),
    );
    await _loadPromotions();
  }

  Future<void> _confirmDeletePromotion(Promotion promotion) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmDialog(
      context,
      title: l10n.promotionDeleteConfirmTitle,
      content: l10n.promotionDeleteConfirmContent,
      confirmLabel: l10n.promotionDeleteConfirmButton,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed) return;
    try {
      await PromotionAdminService.instance.delete(promotion.id);
      await _loadPromotions();
    } catch (e) {
      if (!mounted) return;
      setState(() => _promotionsError = '$e');
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

  Future<void> _openExtraDisplay() async {
    final l10n = AppLocalizations.of(context)!;
    final mode = await showDialog<ExtraDisplayMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.openExtraDisplayButton),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ExtraDisplayMode.customer),
            child: Row(
              children: [
                const Icon(Icons.tv_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(l10n.roleSelectionCustomerTitle),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ExtraDisplayMode.kitchen),
            child: Row(
              children: [
                const Icon(Icons.soup_kitchen_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(l10n.roleSelectionKitchenTitle),
              ],
            ),
          ),
        ],
      ),
    );
    if (mode == null || !mounted) return;
    final ok = await ExtraDisplayLauncher.open(mode);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.openExtraDisplayFailedMessage)),
    );
  }

  Future<void> _disconnect() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await confirmDialog(
      context,
      title: l10n.disconnectTitle,
      content: l10n.disconnectContent,
      confirmLabel: l10n.disconnectLabel,
      cancelLabel: l10n.cancel,
    );
    if (ok && mounted) {
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

  Future<void> _exportBackup() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _exportingBackup = true);
    try {
      final path = await BackupService().exportBackupToFile(
        ShopConfigService.instance.shopName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null ? l10n.exportBackupCancelledMessage : l10n.exportBackupSavedMessage,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportBackupFailedMessage)),
      );
    } finally {
      if (mounted) setState(() => _exportingBackup = false);
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

  Widget _accountCard(ServerClient client, AppLocalizations l10n) => _Card(
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
      );

  Widget _shopDetailsCard(AppLocalizations l10n) => _Card(
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
              const SizedBox(height: 14),
              AppTextField(
                label: l10n.promptpayIdFieldLabel,
                controller: _shopPromptPayController,
                hintText: l10n.promptpayIdFieldHint,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final digits = PromptPayQr.sanitize(v);
                  if (digits.length != 10 && digits.length != 13) {
                    return l10n.promptpayIdValidatorError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: l10n.promptpayLabelFieldLabel,
                controller: _shopPromptPayLabelController,
                hintText: l10n.promptpayLabelFieldHint,
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
      );

  Widget _connectionCard(ServerClient client, AppLocalizations l10n) => _Card(
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
                  side: const BorderSide(color: AppColors.terracottaDark),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _printerCard(AppLocalizations l10n) => _Card(
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
                value: _printerDeviceName ?? l10n.printerNotSelectedValue,
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
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceRow(
                      icon: Icons.receipt_long,
                      label: l10n.paperSize58,
                      selected: _paperSize == ReceiptPaperSize.mm58,
                      onTap: () => _setPaperSize(ReceiptPaperSize.mm58),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ChoiceRow(
                      icon: Icons.receipt_long,
                      label: l10n.paperSize80,
                      selected: _paperSize == ReceiptPaperSize.mm80,
                      onTap: () => _setPaperSize(ReceiptPaperSize.mm80),
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
      );

  Widget _languageCard(AppLocalizations l10n) => _Card(
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
      );

  Widget _extraDisplayCard(AppLocalizations l10n) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openExtraDisplay,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(l10n.openExtraDisplayButton),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.openExtraDisplayHint,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      );

  Widget _serverCard(BuildContext context, AppLocalizations l10n) => _Card(
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ServerStatusScreen()),
            ),
            icon: const Icon(Icons.dns_outlined, size: 16),
            label: Text(l10n.serverStatusButton),
          ),
        ),
      );

  Widget _backupCard(AppLocalizations l10n) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _exportingBackup ? null : _exportBackup,
                icon: _exportingBackup
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_outlined, size: 16),
                label: Text(l10n.exportBackupButton),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.exportBackupHint,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      );

  Widget _advertisingCard(AppLocalizations l10n) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.advertisingSectionHint,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 14),
            if (_adSlides.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.advertisingEmptyMessage,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              )
            else
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorderItem: _reorderAdSlide,
                // The default drag handle overlays an icon on top of each
                // item's trailing edge (Stack + Positioned, see
                // ReorderableListView source) — that was landing directly on
                // top of this row's own preview/mute/delete icon buttons.
                // Using an explicit handle instead avoids the collision.
                buildDefaultDragHandles: false,
                children: [
                  for (final (index, slide) in _adSlides.indexed)
                    _AdSlideRow(
                      key: ValueKey(slide.id),
                      index: index,
                      slide: slide,
                      durationController: _adDurationControllers[slide.id]!,
                      durationLabel: l10n.advertisingDurationLabel,
                      playsUntilEndLabel: l10n.advertisingPlaysUntilEndLabel,
                      deleteTooltip: l10n.advertisingDeleteSlideTooltip,
                      previewTooltip: l10n.advertisingPreviewTooltip,
                      muteTooltip: l10n.advertisingMuteTooltip,
                      unmuteTooltip: l10n.advertisingUnmuteTooltip,
                      onDurationChanged: (seconds) => _updateAdDuration(slide.id, seconds),
                      onMutedChanged: (muted) => _updateAdMuted(slide.id, muted),
                      onDelete: () => _deleteAdSlide(slide.id),
                    ),
                ],
              ),
            if (_adsError != null) ...[
              const SizedBox(height: 8),
              Text(
                _adsError!,
                style: const TextStyle(color: AppColors.terracottaDark, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            if (_uploadingAd) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(_uploadProgress * 100).round()}%',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _uploadingAd ? null : _pickAndUploadAd,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                label: Text(l10n.advertisingAddSlideButton),
              ),
            ),
          ],
        ),
      );

  Widget _promotionsCard(AppLocalizations l10n) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_promotions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.promotionsEmptyMessage,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              )
            else
              ..._promotions.map((promotion) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(promotion.name),
                      subtitle: Text(_promotionTypeLabel(l10n, promotion)),
                      leading: Icon(
                        promotion.active ? Icons.toggle_on : Icons.toggle_off,
                        color: promotion.active ? AppColors.primary : AppColors.muted,
                        size: 32,
                      ),
                      onTap: () => _openPromotionEditor(existing: promotion),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.terracottaDark),
                        onPressed: () => _confirmDeletePromotion(promotion),
                      ),
                    ),
                  )),
            if (_promotionsError != null) ...[
              const SizedBox(height: 8),
              Text(
                _promotionsError!,
                style: const TextStyle(color: AppColors.terracottaDark, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openPromotionEditor(),
                icon: const Icon(Icons.sell_outlined, size: 16),
                label: Text(l10n.promotionsAddButton),
              ),
            ),
          ],
        ),
      );

  String _promotionTypeLabel(AppLocalizations l10n, Promotion promotion) {
    final type = switch (promotion.type) {
      'percent' => l10n.promotionTypePercent,
      'flat' => l10n.promotionTypeFlat,
      'bogo' => l10n.promotionTypeBogo,
      'code' => l10n.promotionTypeCode,
      'combo' => l10n.promotionTypeCombo,
      'min_spend' => l10n.promotionTypeMinSpend,
      'tiered' => l10n.promotionTypeTiered,
      _ => promotion.type,
    };
    final scope = switch (promotion.scopeType) {
      'item' => l10n.promotionScopeItem,
      'category' => promotion.scopeCategory ?? l10n.promotionScopeCategory,
      _ => l10n.promotionScopeShop,
    };
    return '$type · $scope';
  }

  Widget _dangerZoneCard(AppLocalizations l10n) => _Card(
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
      );

  Widget _embeddedShell(BuildContext context, AppLocalizations l10n, Widget body) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.settingsLabel,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: Container(color: AppColors.background, child: body)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = ServerClient.instance;
    final l10n = AppLocalizations.of(context)!;

    if (_printer == null || _language == null || _paperSize == null) {
      const loading = Center(child: CircularProgressIndicator());
      return widget.embedded
          ? _embeddedShell(context, l10n, loading)
          : Scaffold(
              appBar: AppBar(
                title: Text(l10n.settingsLabel),
                backgroundColor: Colors.white,
                foregroundColor: AppColors.ink,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
              backgroundColor: AppColors.background,
              body: loading,
            );
    }

    // Same sections either way — only how they're presented differs: one
    // long scrolling list on a full page (phone), a Discord-style category
    // sidebar + single-section content pane when embedded in the desktop
    // dialog (see build()'s two branches below).
    final sections = <_SettingsSection>[
      _SettingsSection(
        label: l10n.settingsAccountSectionLabel,
        icon: Icons.person_outline,
        builder: () => _accountCard(client, l10n),
      ),
      if (client.canManageShop && _shopLoaded)
        _SettingsSection(
          label: l10n.shopDetailsSectionLabel,
          icon: Icons.storefront_outlined,
          builder: () => _shopDetailsCard(l10n),
        ),
      _SettingsSection(
        label: l10n.connectionSectionLabel,
        icon: Icons.wifi,
        builder: () => _connectionCard(client, l10n),
      ),
      _SettingsSection(
        label: l10n.printerSectionLabel,
        icon: Icons.print_outlined,
        builder: () => _printerCard(l10n),
      ),
      _SettingsSection(
        label: l10n.languageSectionLabel,
        icon: Icons.language,
        builder: () => _languageCard(l10n),
      ),
      if (isWindowsDesktop)
        _SettingsSection(
          label: l10n.extraDisplaySectionLabel,
          icon: Icons.open_in_new,
          builder: () => _extraDisplayCard(l10n),
        ),
      if (client.isOwner && isWindowsDesktop && _localServerRunning)
        _SettingsSection(
          label: l10n.serverSectionLabel,
          icon: Icons.dns_outlined,
          builder: () => _serverCard(context, l10n),
        ),
      if (client.isOwner)
        _SettingsSection(
          label: l10n.backupSectionLabel,
          icon: Icons.backup_outlined,
          builder: () => _backupCard(l10n),
        ),
      if (client.canManageShop && _adsLoaded)
        _SettingsSection(
          label: l10n.advertisingSectionLabel,
          icon: Icons.slideshow_outlined,
          builder: () => _advertisingCard(l10n),
        ),
      if (client.canManageShop && _promotionsLoaded)
        _SettingsSection(
          label: l10n.promotionsSectionLabel,
          icon: Icons.sell_outlined,
          builder: () => _promotionsCard(l10n),
        ),
      if (client.isOwner)
        _SettingsSection(
          label: l10n.dangerZoneSectionLabel,
          icon: Icons.warning_amber_outlined,
          builder: () => _dangerZoneCard(l10n),
        ),
    ];

    if (widget.embedded) {
      final selected = _selectedCategory.clamp(0, sections.length - 1);
      return _embeddedShell(
        context,
        l10n,
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 180,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (var i = 0; i < sections.length; i++)
                    _SettingsCategoryTile(
                      icon: sections[i].icon,
                      label: sections[i].label,
                      selected: i == selected,
                      onTap: () => setState(() => _selectedCategory = i),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Container(
                color: AppColors.background,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sections[selected].label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      sections[selected].builder(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsLabel),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) const SizedBox(height: 20),
                _SectionLabel(sections[i].label),
                sections[i].builder(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One category in the embedded desktop dialog's sidebar — `builder` is
/// deferred (not a plain `Widget`) purely so the full-page list can share
/// the exact same section definitions without constructing every card's
/// widget tree up front when only one is ever shown at a time in that mode.
class _SettingsSection {
  const _SettingsSection({
    required this.label,
    required this.icon,
    required this.builder,
  });
  final String label;
  final IconData icon;
  final Widget Function() builder;
}

class _SettingsCategoryTile extends StatelessWidget {
  const _SettingsCategoryTile({
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.ink,
                ),
              ),
            ),
          ],
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

class _AdSlideRow extends StatelessWidget {
  const _AdSlideRow({
    required super.key,
    required this.index,
    required this.slide,
    required this.durationController,
    required this.durationLabel,
    required this.playsUntilEndLabel,
    required this.deleteTooltip,
    required this.previewTooltip,
    required this.muteTooltip,
    required this.unmuteTooltip,
    required this.onDurationChanged,
    required this.onMutedChanged,
    required this.onDelete,
  });

  /// Position within the reorderable list — needed by
  /// [ReorderableDragStartListener] since `buildDefaultDragHandles` is off
  /// for this list (see call site).
  final int index;
  final AdSlideInfo slide;
  final TextEditingController durationController;
  final String durationLabel;
  final String playsUntilEndLabel;
  final String deleteTooltip;
  final String previewTooltip;
  final String muteTooltip;
  final String unmuteTooltip;
  final ValueChanged<String> onDurationChanged;
  final ValueChanged<bool> onMutedChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = 'http://${ServerClient.instance.baseUrl}${slide.url}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.drag_indicator, size: 18, color: AppColors.muted),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => showDialog(context: context, builder: (_) => _AdPreviewDialog(slide: slide)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 52,
                child: slide.type == 'video'
                    ? const ColoredBox(
                        color: AppColors.background,
                        child: Icon(Icons.play_circle_outline, color: AppColors.muted),
                      )
                    : Image.network(thumbnailUrl, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: slide.type == 'video'
                ? Row(
                    children: [
                      Expanded(
                        child: Text(playsUntilEndLabel,
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ),
                      IconButton(
                        icon: Icon(
                          slide.muted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        tooltip: slide.muted ? unmuteTooltip : muteTooltip,
                        onPressed: () => onMutedChanged(!slide.muted),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: 56,
                        child: TextField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(isDense: true),
                          onSubmitted: onDurationChanged,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(durationLabel, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.muted),
            tooltip: previewTooltip,
            onPressed: () => showDialog(context: context, builder: (_) => _AdPreviewDialog(slide: slide)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.terracottaDark),
            tooltip: deleteTooltip,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Full-size preview of an uploaded ad slide (Settings → Advertising), so an
/// owner/manager can check what's actually playing on the customer display
/// without needing a second device — images render at native fit, video gets
/// real playback controls (default `AdaptiveVideoControls`, unlike the
/// customer display's own `NoVideoControls` kiosk view).
class _AdPreviewDialog extends StatefulWidget {
  const _AdPreviewDialog({required this.slide});
  final AdSlideInfo slide;

  @override
  State<_AdPreviewDialog> createState() => _AdPreviewDialogState();
}

class _AdPreviewDialogState extends State<_AdPreviewDialog> {
  Player? _player;
  VideoController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.slide.type == 'video') {
      final player = Player();
      _controller = VideoController(player);
      _player = player;
      // Starts at the same mute state the customer display would use, so
      // the preview reflects reality — the adaptive controls still let the
      // owner/manager un-mute here to check the audio itself.
      player.setVolume(widget.slide.muted ? 0 : 100);
      player.open(Media('http://${ServerClient.instance.baseUrl}${widget.slide.url}'));
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final url = 'http://${ServerClient.instance.baseUrl}${widget.slide.url}';
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: (size.width * 0.9).clamp(0, 720),
        height: (size.height * 0.8).clamp(0, 480),
        child: Stack(
          children: [
            Center(
              child: widget.slide.type == 'video' && _controller != null
                  ? Video(controller: _controller!)
                  : Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
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
  // Paired devices load instantly (no active discovery scan) and are the
  // common case — the printer was already paired via Android Bluetooth
  // settings. "Scan" below is the fallback for a printer that's never been
  // paired at the OS level, or USB, which has no "paired" concept at all.
  late Future<List<PrinterDevice>> _future = PrinterService().pairedDevices(
    widget.choice,
  );
  bool _scanned = false;

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
                      _scanned ? l10n.scanningForPrintersLabel : l10n.loadingPairedPrintersLabel,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              );
            }
            if (snapshot.hasError) {
              final isPermissionError = snapshot.error is PrinterPermissionException;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  isPermissionError
                      ? l10n.bluetoothPermissionDeniedMessage
                      : '${snapshot.error}',
                  style: const TextStyle(color: AppColors.terracottaDark),
                ),
              );
            }
            final devices = snapshot.data ?? const [];
            if (devices.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _scanned ? l10n.noPrintersFoundMessage : l10n.noPairedPrintersMessage,
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
          onPressed: () => setState(() {
            _scanned = true;
            _future = PrinterService().scanAvailable(widget.choice);
          }),
          child: Text(l10n.scanForPrintersButton),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
