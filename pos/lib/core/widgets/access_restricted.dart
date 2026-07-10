import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Shown when a screen is reached by a role that isn't permitted to use it
/// (nav already hides the entry point — this is defense in depth in case
/// the screen is ever reached another way).
class AccessRestrictedScreen extends StatelessWidget {
  const AccessRestrictedScreen({super.key, required this.feature});

  final String feature;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 42, color: AppColors.muted),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.accessRestrictedMessage(feature),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
