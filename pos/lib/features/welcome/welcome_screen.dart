import 'package:flutter/material.dart';

import '../../core/services/local_server_launcher.dart';
import '../../core/services/mobile_server_launcher.dart';
import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_message.dart';
import '../../core/window/platform_window.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import '../connect/connect_screen.dart';
import '../shop_setup/shop_setup_choice_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _openingRegister = false;

  // Self-hosting means launching a local server: a detached exe on Windows
  // (can also serve other devices on the LAN), or an in-process loopback-only
  // isolate on mobile (this device only, see MobileServerLauncher). Neither
  // is wired up on other platforms (macOS/Linux desktop, Web) — the button is
  // disabled there, since no server exists to point ServerClient.baseUrl at.
  Future<void> _openRegister() async {
    if (!isWindowsDesktop && !isMobile) return;

    setState(() => _openingRegister = true);
    final ready = isWindowsDesktop
        ? await LocalServerLauncher.instance.ensureRunning()
        : await MobileServerLauncher.instance.ensureRunning();
    if (!mounted) return;
    setState(() => _openingRegister = false);
    if (!ready) {
      showAppMessage(
        context,
        AppLocalizations.of(context)!.welcomeOpenRegisterFailedMessage,
        isError: true,
      );
      return;
    }
    ServerClient.instance.baseUrl = '127.0.0.1:8080';

    if (!mounted) return;
    final description = AppLocalizations.of(context)!.welcomeOpenRegisterDescription;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(serverAddress: description),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 88,
                    height: 88,
                  ),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context)!.welcomeAppTitle, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.appTagline,
                    style: TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Primary daily action — local / offline login
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.point_of_sale, size: 18),
                              label: _openingRegister
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                                    )
                                  : Text(AppLocalizations.of(context)!.welcomeOpenRegisterButton),
                              onPressed: (_openingRegister || (!isWindowsDesktop && !isMobile)) ? null : _openRegister,
                            ),
                          ),
                          if (!isWindowsDesktop && !isMobile) ...[
                            const SizedBox(height: 6),
                            Text(
                              AppLocalizations.of(context)!.welcomeOpenRegisterUnavailableNote,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.muted, fontSize: 11),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  AppLocalizations.of(context)!.welcomeOrDivider,
                                  style: const TextStyle(
                                      color: AppColors.muted, fontSize: 12),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Client device connecting to a remote host
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.wifi, size: 18),
                              label: Text(AppLocalizations.of(context)!.welcomeConnectServerButton),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const ConnectScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Always enabled — a shop can be created/restored
                          // onto a remote server regardless of this device's
                          // own state. The offline (local) path is where "a
                          // shop already exists here" actually matters, and
                          // it's blocked there instead: CreateShopScreen's
                          // _checkTargetAvailable for local mode, and
                          // RestoreShopScreen's _canUseLocal.
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              icon: const Icon(Icons.add_business_outlined,
                                  size: 16),
                              label: Text(AppLocalizations.of(context)!.welcomeCreateShopButton),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const ShopSetupChoiceScreen()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.welcomeVersionInfo,
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
