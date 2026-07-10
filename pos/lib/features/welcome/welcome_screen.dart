import 'package:flutter/material.dart';

import '../../core/services/local_server_launcher.dart';
import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/window/platform_window.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import '../role_select/role_selection_screen.dart';
import '../shop_setup/create_shop_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _openingRegister = false;

  Future<void> _openRegister() async {
    if (isWindowsDesktop) {
      setState(() => _openingRegister = true);
      final ready = await LocalServerLauncher.instance.ensureRunning();
      if (!mounted) return;
      setState(() => _openingRegister = false);
      if (!ready) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.welcomeOpenRegisterFailedMessage)),
        );
        return;
      }
      ServerClient.instance.baseUrl = '127.0.0.1:8080';
    }

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
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_cafe,
                      color: AppColors.accent,
                      size: 34,
                    ),
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
                              onPressed: _openingRegister ? null : _openRegister,
                            ),
                          ),
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
                                    builder: (_) => const RoleSelectionScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // First-time setup only
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              icon: const Icon(Icons.add_business_outlined,
                                  size: 16),
                              label: Text(AppLocalizations.of(context)!.welcomeCreateShopButton),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const CreateShopScreen()),
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
