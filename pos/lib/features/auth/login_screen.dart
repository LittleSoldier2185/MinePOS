import 'package:flutter/material.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../l10n/app_localizations.dart';
import '../cashier/services/menu_service.dart';
import '../cashier/services/order_service.dart';
import '../connect/models/device_purpose.dart';
import '../home/home_placeholder_screen.dart';
import '../kitchen/kitchen_display_screen.dart';
import '../manager/services/shop_config_service.dart';
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
  final _deviceNameController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _signingIn = false;
  bool _rememberMe = false;
  bool _autoLogin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    AppSettingsService.instance.getDeviceName().then((name) {
      if (mounted && name != null) _deviceNameController.text = name;
    });
    AppSettingsService.instance.getLastUsername().then((u) {
      if (mounted && u != null && u.isNotEmpty) {
        setState(() {
          _usernameController.text = u;
          _rememberMe = true;
        });
      }
    });
    AppSettingsService.instance.getAutoLogin().then((v) {
      if (mounted && v) setState(() => _autoLogin = _rememberMe = true);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _deviceNameController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _signingIn = true;
      _error = null;
    });

    final deviceName = _deviceNameController.text.trim();
    final result = await _authService.login(
      _usernameController.text,
      _passwordController.text,
      deviceName,
    );

    if (!mounted) return;
    setState(() => _signingIn = false);

    if (result.success) {
      ServerClient.instance.role = result.role;
      ServerClient.instance.username = result.username;
      ServerClient.instance.userId = result.id;
      ServerClient.instance.name = result.name;
      ServerClient.instance.avatarBase64 = result.avatarBase64;
      await AppSettingsService.instance.setDeviceName(deviceName);

      await AppSettingsService.instance.setLastUsername(
        _rememberMe ? _usernameController.text.trim() : null,
      );
      if (_autoLogin) {
        await AppSettingsService.instance.saveSession(
          baseUrl: ServerClient.instance.baseUrl!,
          token: ServerClient.instance.token!,
          deviceName: deviceName,
          purpose: widget.purpose.name,
        );
        await AppSettingsService.instance.setAutoLogin(true);
      } else {
        // Guards against a stale remembered session (a different account, or
        // this same one from before auto-login was unchecked) still silently
        // signing in next launch.
        await AppSettingsService.instance.clearSession();
        await AppSettingsService.instance.setAutoLogin(false);
      }

      // Both services start out seeded with local-only defaults/empty state
      // — without this, every screen would show stale placeholder data (or
      // nothing) until something happened to trigger a sync, making a fresh
      // login look like menu items/order history "disappeared" after a
      // restart when they were actually sitting on the server the whole
      // time. Kitchen-only sign-in skips this: that screen only needs live
      // orders over its own WebSocket, not the cashier menu/order history.
      if (widget.purpose != DevicePurpose.kitchenOnly) {
        await Future.wait([
          MenuService.instance.fetchFromServer(),
          OrderService.instance.loadFromServer(),
          ShopConfigService.instance.fetch(),
        ]);
        MenuService.instance.connect();
        OrderService.instance.connect();
      }

      if (!mounted) return;
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

  // Desktop gets a split branding/form layout; mobile keeps a single centered card.
  static const _desktopBreakpoint = 900.0;

  Widget _formFields(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        AppTextField(
          label: l10n.deviceNameLabel,
          hintText: l10n.deviceNameHint,
          controller: _deviceNameController,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? l10n.deviceNameRequiredValidator
              : null,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: l10n.usernameOrEmailLabel,
          controller: _usernameController,
          focusNode: _usernameFocus,
          textInputAction: TextInputAction.next,
          // Enter in username → jump to password.
          onSubmitted: (_) => _passwordFocus.requestFocus(),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? l10n.usernameRequiredValidator
              : null,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: l10n.passwordLabel,
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          // Enter in password → sign in (unless one's already in flight).
          onSubmitted: (_) {
            if (!_signingIn) _signIn();
          },
          validator: (v) =>
              (v == null || v.isEmpty) ? l10n.passwordRequiredValidator : null,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        // Auto-login needs a remembered username to fall back to (see
        // main.dart's idle-timeout path), so the two are linked: ticking
        // auto-login forces "Remember me" on; clearing "Remember me" clears it.
        _CheckRow(
          value: _rememberMe,
          label: l10n.rememberMeLabel,
          onChanged: (v) => setState(() {
            _rememberMe = v;
            if (!v) _autoLogin = false;
          }),
        ),
        _CheckRow(
          value: _autoLogin,
          label: l10n.autoLoginLabel,
          onChanged: (v) => setState(() {
            _autoLogin = v;
            if (v) _rememberMe = true;
          }),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
            ),
            child: Text(l10n.loginForgotPasswordLink),
          ),
        ),
        if (_error != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _error!,
              style: const TextStyle(
                color: AppColors.terracottaDark,
                fontSize: 12,
              ),
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
                : Text(l10n.loginSignInButton),
          ),
        ),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 88,
                  height: 88,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.loginScreenTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.loginConnectedTo(widget.serverAddress),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _formFields(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _desktopLayout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.primary,
            padding: const EdgeInsets.all(48),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // On the dark olive panel the logo's own olive disc would
                  // vanish — sit it on a light circular chip so it reads.
                  Container(
                    width: 160,
                    height: 160,
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset('assets/images/logo.png'),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.loginScreenTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.loginConnectedTo(widget.serverAddress),
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Form(key: _formKey, child: _formFields(context)),
              ),
            ),
          ),
        ),
      ],
    );
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
        child: LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= _desktopBreakpoint
              ? _desktopLayout(context)
              : _mobileLayout(context),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
