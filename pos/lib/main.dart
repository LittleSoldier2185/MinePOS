import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

import 'core/services/app_settings_service.dart';
import 'core/services/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/window/custom_title_bar.dart';
import 'core/window/platform_window.dart';
import 'features/welcome/welcome_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const MinePosApp());
}

class MinePosApp extends StatefulWidget {
  const MinePosApp({super.key});

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
      home: const WelcomeScreen(),
    );
  }
}
