import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'core/theme/app_theme.dart';
import 'core/window/custom_title_bar.dart';
import 'core/window/platform_window.dart';
import 'features/welcome/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class MinePosApp extends StatelessWidget {
  const MinePosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MinePOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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
