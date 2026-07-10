import 'package:flutter/material.dart';

import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../l10n/app_localizations.dart';
import '../connect/models/device_purpose.dart';
import '../home/home_placeholder_screen.dart';
import '../kitchen/kitchen_display_screen.dart';
import 'forgot_password_screen.dart';
import 'services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.serverAddress,
    this.purpose = DevicePurpose.staffHub,
  });

  final String serverAddress;
  final DevicePurpose purpose;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _signingIn = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _signingIn = true;
      _error = null;
    });

    final result = await _authService.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _signingIn = false);

    if (result.success) {
      ServerClient.instance.role = result.role;
      ServerClient.instance.username = result.username;
      final welcomeMessage = AppLocalizations.of(context)!.loginWelcomeMessage;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => widget.purpose == DevicePurpose.kitchenOnly
              ? const KitchenDisplayScreen(standalone: true)
              : HomePlaceholderScreen(title: welcomeMessage),
        ),
        (route) => false,
      );
    } else {
      setState(() => _error = AppLocalizations.of(context)!.loginErrorMessage);
    }
  }

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
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
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
                      child: const Icon(Icons.local_cafe, color: AppColors.accent, size: 34),
                    ),
                    const SizedBox(height: 20),
                    Text(AppLocalizations.of(context)!.loginScreenTitle, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.loginConnectedTo(widget.serverAddress),
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            AppTextField(
                              label: AppLocalizations.of(context)!.usernameOrEmailLabel,
                              controller: _usernameController,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.usernameRequiredValidator : null,
                            ),
                            const SizedBox(height: 14),
                            AppTextField(
                              label: AppLocalizations.of(context)!.passwordLabel,
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? AppLocalizations.of(context)!.passwordRequiredValidator : null,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                ),
                                child: Text(AppLocalizations.of(context)!.loginForgotPasswordLink),
                              ),
                            ),
                            if (_error != null) ...[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: AppColors.terracottaDark, fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _signingIn ? null : _signIn,
                                child: _signingIn
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.accent,
                                        ),
                                      )
                                    : Text(AppLocalizations.of(context)!.loginSignInButton),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
