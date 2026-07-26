import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'core/services/app_settings_service.dart';
import 'core/services/local_server_launcher.dart';
import 'core/services/locale_controller.dart';
import 'core/services/mobile_server_launcher.dart';
import 'core/services/server_client.dart';
import 'core/theme/app_theme.dart';
import 'core/window/custom_title_bar.dart';
import 'core/window/platform_window.dart';
import 'features/auth/services/auth_service.dart';
import 'features/cashier/services/menu_service.dart';
import 'features/cashier/services/order_service.dart';
import 'features/customer_display/customer_display_screen.dart';
import 'features/home/home_placeholder_screen.dart';
import 'features/kitchen/kitchen_display_screen.dart';
import 'features/manager/services/shop_config_service.dart';
import 'features/welcome/welcome_screen.dart';
import 'l10n/app_localizations.dart';

/// Silently restores a "remember me" session saved at login, so the app can
/// skip Welcome/Connect/Login on launch. Returns null (falling back to the
/// normal flow) if nothing was remembered, or the remembered token turns out
/// to be expired/revoked — [AuthService.me] is what tells the two apart from
/// a stale/garbage session, so we don't strand the user on a blank screen.
Future<Widget?> _tryAutoLogin() async {
  final remembered = await AppSettingsService.instance.getSession();
  if (remembered == null) return null;

  // A self-hosted shop's server isn't guaranteed to already be running when
  // the app relaunches: on Windows it's a detached process that only
  // survives a full reboot; on mobile it's an in-process isolate that dies
  // with the app every single time. Relaunch/re-attach it first, same as
  // "Open Register" does, or /auth/me below would fail every time on mobile.
  if (remembered.baseUrl.startsWith('127.0.0.1')) {
    final ready = isWindowsDesktop
        ? await LocalServerLauncher.instance.ensureRunning()
        : isMobile
            ? await MobileServerLauncher.instance.ensureRunning()
            : false;
    if (!ready) return null; // Leave the session intact — retry next launch.
  }

  ServerClient.instance.baseUrl = remembered.baseUrl;
  ServerClient.instance.token = remembered.token;
  ServerClient.instance.deviceName = remembered.deviceName;

  final result = await AuthService().me();
  if (!result.success) {
    // Only drop the *persisted* remembered session on a definite rejection
    // (expired, deactivated, revoked). A connection-level failure just means
    // the server (or a self-hosted install still finishing its own startup)
    // isn't reachable *this instant* — wiping it over that would have
    // silently defeated "remember me" on its very first hiccup. Either way,
    // reset the runtime ServerClient fields so a half-populated session
    // doesn't leak into the WelcomeScreen fallback below.
    if (result.unreachable) {
      ServerClient.instance.baseUrl = null;
      ServerClient.instance.token = null;
      ServerClient.instance.deviceName = null;
    } else {
      ServerClient.instance.clear();
    }
    return null;
  }
  ServerClient.instance.role = result.role;
  ServerClient.instance.username = result.username;
  ServerClient.instance.userId = result.id;
  ServerClient.instance.name = result.name;
  ServerClient.instance.avatarBase64 = result.avatarBase64;

  // Mirrors login_screen.dart's post-login sync (see its comment for why) —
  // skipped for a remembered kitchen-only station the same way a fresh
  // kitchen-only sign-in skips it.
  final isKitchenOnly = remembered.purpose == 'kitchenOnly';
  if (!isKitchenOnly) {
    await Future.wait([
      MenuService.instance.fetchFromServer(),
      OrderService.instance.loadFromServer(),
      ShopConfigService.instance.fetch(),
    ]);
    MenuService.instance.connect();
    OrderService.instance.connect();
  }
  return isKitchenOnly ? const KitchenDisplayScreen(standalone: true) : const HomePlaceholderScreen();
}

/// Parses the flags a second, detached OS process is launched with (see
/// `ExtraDisplayLauncher`) to open straight into a display screen instead of
/// the normal Welcome/Connect/Login flow, reusing the launching session's
/// server address and auth token — same device/login, just another window.
({String mode, String address, String token})? _extraDisplayArgs(List<String> args) {
  String? mode, address, token;
  for (final arg in args) {
    if (arg.startsWith('--extra-display=')) mode = arg.substring('--extra-display='.length);
    if (arg.startsWith('--address=')) address = arg.substring('--address='.length);
    if (arg.startsWith('--token=')) token = arg.substring('--token='.length);
  }
  if (mode == null || address == null || token == null) return null;
  return (mode: mode, address: address, token: token);
}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // One-time global init for the customer display's ad-slideshow video
  // playback (see customer_display_screen.dart's _AdSlideshowView).
  MediaKit.ensureInitialized();

  final language = await AppSettingsService.instance.getLanguage();
  LocaleController.instance.setLanguage(language);

  if (isWindowsDesktop) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        minimumSize: Size(480, 720),
        titleBarStyle: TitleBarStyle.hidden,
        windowButtonVisibility: false,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  final extraDisplay = _extraDisplayArgs(args);
  if (extraDisplay != null) {
    ServerClient.instance.baseUrl = extraDisplay.address;
    ServerClient.instance.token = extraDisplay.token;
    runApp(MinePosApp(
      home: extraDisplay.mode == 'kitchen'
          ? const KitchenDisplayScreen(standalone: true)
          : const CustomerDisplayScreen(),
    ));
    return;
  }

  final autoLoginHome = await _tryAutoLogin();
  runApp(MinePosApp(home: autoLoginHome ?? const WelcomeScreen()));
}

class MinePosApp extends StatefulWidget {
  const MinePosApp({super.key, this.home = const WelcomeScreen()});

  final Widget home;

  @override
  State<MinePosApp> createState() => _MinePosAppState();
}

class _MinePosAppState extends State<MinePosApp> {
  @override
  void initState() {
    super.initState();
    LocaleController.instance.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    LocaleController.instance.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MinePOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(LocaleController.instance.locale),
      locale: LocaleController.instance.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        if (!isWindowsDesktop || child == null) return child ?? const SizedBox.shrink();
        return Column(
          children: [
            const CustomTitleBar(),
            Expanded(child: child),
          ],
        );
      },
      home: widget.home,
    );
  }
}
