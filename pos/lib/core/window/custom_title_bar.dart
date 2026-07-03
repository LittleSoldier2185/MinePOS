import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../theme/app_colors.dart';

/// Replaces the native Windows title bar. Only meant to be mounted when
/// [isWindowsDesktop] is true — see main.dart.
class CustomTitleBar extends StatefulWidget {
  const CustomTitleBar({super.key});

  static const double height = 36;

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.isMaximized().then((value) {
      if (mounted) setState(() => _isMaximized = value);
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _isMaximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _isMaximized = false);

  Future<void> _toggleMaximize() async {
    if (_isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: CustomTitleBar.height,
      color: AppColors.ink,
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.local_cafe, size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'MinePOS',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _TitleBarButton(
            icon: Icons.remove,
            onPressed: () => windowManager.minimize(),
          ),
          _TitleBarButton(
            icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
            iconSize: _isMaximized ? 13 : 14,
            onPressed: _toggleMaximize,
          ),
          _TitleBarButton(
            icon: Icons.close,
            hoverColor: AppColors.terracottaDark,
            onPressed: () => windowManager.close(),
          ),
        ],
      ),
    );
  }
}

class _TitleBarButton extends StatelessWidget {
  const _TitleBarButton({
    required this.icon,
    required this.onPressed,
    this.iconSize = 14,
    this.hoverColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double iconSize;
  final Color? hoverColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CustomTitleBar.height,
      height: CustomTitleBar.height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          hoverColor: hoverColor ?? Colors.white.withValues(alpha: 0.1),
          child: Icon(icon, size: iconSize, color: AppColors.accent),
        ),
      ),
    );
  }
}
