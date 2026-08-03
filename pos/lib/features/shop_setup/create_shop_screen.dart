import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/services/local_server_launcher.dart';
import '../../core/services/mobile_server_launcher.dart';
import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/window/platform_window.dart';
import '../../l10n/app_localizations.dart';
import '../auth/services/auth_service.dart';
import '../cashier/services/menu_service.dart';
import '../cashier/services/order_service.dart';
import '../connect/services/connection_service.dart';
import '../home/home_placeholder_screen.dart';
import '../manager/services/shop_config_service.dart';
import 'models/shop_setup_data.dart';
import 'services/shop_setup_service.dart';
import 'steps/admin_account_step.dart';
import 'steps/connection_mode_step.dart';
import 'steps/printer_setup_step.dart';
import 'steps/setup_summary_step.dart';
import 'steps/shop_details_step.dart';

// "Local (this device)" always means 127.0.0.1:8080 — on Windows the app
// launches a detached server exe (LocalServerLauncher); on mobile it spawns
// an in-process background isolate bound to loopback only
// (MobileServerLauncher). Either way, the wizard triggers the launch itself
// before calling /setup.
const _localSetupAddress = '127.0.0.1:8080';

const _stepCount = 5;

class CreateShopScreen extends StatefulWidget {
  const CreateShopScreen({super.key});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  final _data = ShopSetupData();
  final _pageController = PageController();
  final _detailsFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();
  final _connectionFormKey = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _submitting = false;

  GlobalKey<FormState>? get _currentFormKey {
    switch (_currentStep) {
      case 0:
        return _connectionFormKey;
      case 1:
        return _detailsFormKey;
      case 2:
        return _adminFormKey;
      default:
        return null;
    }
  }

  Future<void> _next() async {
    if (_submitting) return;
    final formKey = _currentFormKey;
    if (formKey != null && !(formKey.currentState?.validate() ?? true)) return;

    if (_currentStep == 0) {
      setState(() => _submitting = true);
      final blocked = await _checkTargetAvailable();
      if (!mounted) return;
      setState(() => _submitting = false);
      if (blocked != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blocked)));
        return;
      }
    }

    if (_currentStep == _stepCount - 1) {
      _finish();
      return;
    }

    setState(() => _currentStep++);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Checks whether the chosen connection target (this device, or the
  /// entered server address) already has a shop set up, so the wizard can
  /// block right after step 0 instead of only failing at the final
  /// `POST /setup` after the whole form is filled in. Returns an error
  /// message when blocked, null when clear to proceed.
  Future<String?> _checkTargetAvailable() async {
    final l10n = AppLocalizations.of(context)!;
    if (_data.connectionMode == ConnectionMode.local) {
      final hasShop = isWindowsDesktop
          ? LocalServerLauncher.instance.hasLocalShop()
          : isMobile
              ? await MobileServerLauncher.instance.hasLocalShop()
              : false;
      return hasShop ? l10n.shopAlreadyExistsLocalError : null;
    }
    final status = await ConnectionService().checkStatus(_data.cloudServerAddress);
    if (!status.reachable) return l10n.connectFailureError;
    if (status.hasShop) return l10n.shopAlreadyExistsRemoteError;
    return null;
  }

  void _back() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context)!;

    final targetAddress = _data.connectionMode == ConnectionMode.local
        ? _localSetupAddress
        : _data.cloudServerAddress.trim();

    setState(() => _submitting = true);
    String recoveryCode = '';
    try {
      if (_data.connectionMode == ConnectionMode.local) {
        final launched = isWindowsDesktop
            ? await LocalServerLauncher.instance.ensureRunning()
            : await MobileServerLauncher.instance.ensureRunning();
        if (!launched) {
          throw Exception(l10n.localServerLaunchFailedError);
        }
      }
      recoveryCode = await ShopSetupService().createShop(_data, targetAddress);

      ServerClient.instance.baseUrl = targetAddress;
      // This device is signing in for the first time as the shop's own
      // owner — no login screen (and so no device-name field) is involved,
      // so seed a sensible default the owner can rename on any later login.
      final deviceName =
          await AppSettingsService.instance.getDeviceName() ?? l10n.defaultDeviceNameOnSetup;
      final result = await AuthService()
          .login(_data.adminUsername, _data.adminPassword, deviceName);
      if (!result.success) {
        throw Exception(
            'Shop was created but automatic sign-in failed — sign in manually.');
      }
      ServerClient.instance.role = result.role;
      ServerClient.instance.username = result.username;
      ServerClient.instance.userId = result.id;
      await AppSettingsService.instance.setDeviceName(deviceName);

      // Mirrors login_screen.dart's post-login sync — without it this
      // screen would carry over whatever menu/orders/shop config were
      // still cached in memory from a previously connected shop.
      await Future.wait([
        MenuService.instance.fetchFromServer(),
        OrderService.instance.loadFromServer(),
        ShopConfigService.instance.fetch(),
      ]);
      MenuService.instance.connect();
      OrderService.instance.connect();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shopSetupFailedMessage('$e'))),
      );
      return;
    }

    if (!mounted) return;
    if (recoveryCode.isNotEmpty) {
      await _showRecoveryCodeDialog(recoveryCode);
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomePlaceholderScreen(
          title: _data.shopName.isEmpty
              ? l10n.shopCreatedDefaultTitle
              : l10n.shopReadyTitle(_data.shopName),
        ),
      ),
      (route) => false,
    );
  }

  /// Shown exactly once, right after bootstrap — the server never returns
  /// this code again (only its bcrypt hash is persisted), so this dialog is
  /// the owner's only chance to save it. Not dismissible except via the
  /// explicit "I've saved it" button, to make skipping past it deliberate.
  Future<void> _showRecoveryCodeDialog(String code) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recoveryCodeDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.recoveryCodeDialogBody),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.terracottaLight),
              ),
              child: SelectableText(
                code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(l10n.recoveryCodeCopiedMessage)),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: Text(l10n.recoveryCodeCopyButton),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.recoveryCodeContinueButton),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createShopAppBarTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Text(
                  l10n.stepIndicator(_currentStep + 1, _stepCount),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / _stepCount,
                      backgroundColor: AppColors.terracottaLight,
                      color: AppColors.primary,
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ConnectionModeStep(formKey: _connectionFormKey, data: _data),
                ShopDetailsStep(formKey: _detailsFormKey, data: _data),
                AdminAccountStep(formKey: _adminFormKey, data: _data),
                PrinterSetupStep(data: _data),
                SetupSummaryStep(data: _data),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : _back,
                        child: Text(l10n.back),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _next,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.accent),
                            )
                          : Text(_currentStep == _stepCount - 1 ? l10n.finishSetupButton : l10n.next),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
