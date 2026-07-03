import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Landing spot after onboarding finishes. Real dashboard (role-based UI,
/// cashier/kitchen/manager screens) is future work.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.primary, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'The dashboard is coming soon.',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
