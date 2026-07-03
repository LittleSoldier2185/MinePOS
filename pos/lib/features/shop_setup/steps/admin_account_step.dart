import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
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
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('First admin account', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'This account has full access to MinePOS.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Username',
              controller: _usernameController,
              onChanged: (v) => widget.data.adminUsername = v,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Password',
              controller: _passwordController,
              obscureText: _obscurePassword,
              onChanged: (v) => widget.data.adminPassword = v,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Confirm Password',
              controller: _confirmController,
              obscureText: _obscureConfirm,
              validator: (v) {
                if (v != _passwordController.text) return 'Passwords do not match';
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
