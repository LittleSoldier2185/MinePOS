import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../models/shop_setup_data.dart';

class AdminAccountStep extends StatefulWidget {
  const AdminAccountStep({super.key, required this.formKey, required this.data});

  final GlobalKey<FormState> formKey;
  final ShopSetupData data;

  @override
  State<AdminAccountStep> createState() => _AdminAccountStepState();
}

class _AdminAccountStepState extends State<AdminAccountStep> {
  late final _usernameController = TextEditingController(text: widget.data.adminUsername);
  late final _passwordController = TextEditingController(text: widget.data.adminPassword);
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminAccountStepTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              l10n.adminAccountStepSubtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: l10n.usernameLabel,
              controller: _usernameController,
              onChanged: (v) => widget.data.adminUsername = v,
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.usernameRequiredValidator : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.passwordLabel,
              controller: _passwordController,
              obscureText: _obscurePassword,
              onChanged: (v) => widget.data.adminPassword = v,
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.passwordRequiredValidator;
                if (v.length < 6) return l10n.passwordMinLengthValidatorError;
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.confirmPasswordLabel,
              controller: _confirmController,
              obscureText: _obscureConfirm,
              validator: (v) {
                if (v != _passwordController.text) return l10n.passwordMismatchValidator;
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
