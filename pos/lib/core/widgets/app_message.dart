import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';
import '../theme/app_colors.dart';
import '../window/platform_window.dart';

void _snack(BuildContext context, String message, bool isError) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.terracottaDark : null,
    ),
  );
}

/// A transient confirmation that an action happened.
///
/// Mobile: always a plain [SnackBar]. Windows desktop: a dismissible card
/// pinned bottom-right (clear of the bottom button row a SnackBar covers)
/// with a countdown bar and an X to close it now — unless the user turned
/// that off in Settings, in which case it's a SnackBar there too.
void showAppMessage(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 4),
}) {
  if (!isWindowsDesktop) {
    _snack(context, message, isError);
    return;
  }
  _showDesktop(context, message, isError, duration);
}

Future<void> _showDesktop(
  BuildContext context,
  String message,
  bool isError,
  Duration duration,
) async {
  // SharedPreferences is in-memory after first load, so this gap is a frame
  // at most; the mounted check covers it either way.
  final useCard = await AppSettingsService.instance.getShowMessageCards();
  if (!context.mounted) return;
  if (!useCard) {
    _snack(context, message, isError);
    return;
  }
  _DesktopMessage.show(context, message, isError: isError, duration: duration);
}

class _DesktopMessage {
  // One at a time — a new message replaces whatever's still showing.
  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String message, {
    required bool isError,
    required Duration duration,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _current?.remove();
    _current = null;

    late final OverlayEntry entry;
    void dismiss() {
      if (_current == entry) _current = null;
      if (entry.mounted) entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => _MessageCard(
        message: message,
        isError: isError,
        duration: duration,
        onDismiss: dismiss,
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _MessageCard extends StatefulWidget {
  const _MessageCard({
    required this.message,
    required this.isError,
    required this.duration,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<_MessageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bar = AnimationController(
    vsync: this,
    duration: widget.duration,
  )
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDismiss();
    })
    ..forward();

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        widget.isError ? AppColors.terracottaDark : AppColors.primary;
    return Positioned(
      top: 20,
      right: 20,
      child: SafeArea(
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Close button on its own line, pinned to the top-right corner.
                Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    onTap: widget.onDismiss,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close, size: 16, color: AppColors.muted),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isError
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        size: 18,
                        color: accent,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Countdown: full → empty over `duration`.
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                  child: AnimatedBuilder(
                    animation: _bar,
                    builder: (_, _) => LinearProgressIndicator(
                      value: 1 - _bar.value,
                      minHeight: 3,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
