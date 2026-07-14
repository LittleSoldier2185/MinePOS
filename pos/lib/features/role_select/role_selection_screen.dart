import 'package:flutter/material.dart';

import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import '../connect/models/device_purpose.dart';
import '../customer_display/customer_display_screen.dart';

/// Reached after [ConnectScreen] has already confirmed a shop exists at
/// the entered address: pick what this device is for. Cashier/Manager
/// stations and Kitchen Displays still sign in normally afterward; a
/// Customer Display connects and goes straight to the live view, no login
/// needed.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.muted),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(AppLocalizations.of(context)!.roleSelectionTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.roleSelectionInstructions,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  _RoleCard(
                    icon: Icons.point_of_sale,
                    title: AppLocalizations.of(context)!.roleSelectionCashierTitle,
                    subtitle: AppLocalizations.of(context)!.roleSelectionCashierSubtitle,
                    onTap: () => _go(context, DevicePurpose.staffHub),
                  ),
                  const SizedBox(height: 12),
                  _RoleCard(
                    icon: Icons.soup_kitchen_outlined,
                    title: AppLocalizations.of(context)!.roleSelectionKitchenTitle,
                    subtitle: AppLocalizations.of(context)!.roleSelectionKitchenSubtitle,
                    onTap: () => _go(context, DevicePurpose.kitchenOnly),
                  ),
                  const SizedBox(height: 12),
                  _RoleCard(
                    icon: Icons.tv_outlined,
                    title: AppLocalizations.of(context)!.roleSelectionCustomerTitle,
                    subtitle: AppLocalizations.of(context)!.roleSelectionCustomerSubtitle,
                    onTap: () => _go(context, DevicePurpose.customerDisplay),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, DevicePurpose purpose) {
    if (purpose == DevicePurpose.customerDisplay) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomerDisplayScreen()),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          serverAddress: ServerClient.instance.baseUrl!,
          purpose: purpose,
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
