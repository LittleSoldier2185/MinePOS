import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// True only when running as a native Windows desktop build.
/// `kIsWeb` must be checked first — `Platform.isWindows` throws on web.
bool get isWindowsDesktop => !kIsWeb && Platform.isWindows;

/// True on Android/iOS. Can self-host a standalone single-device shop
/// (see `MobileServerLauncher`) but — unlike [isWindowsDesktop] — can never
/// be a host other devices connect to.
bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// mDNS/UDP multicast discovery isn't reachable from a browser sandbox, so
/// it's only available on native builds (Windows, Android, etc).
bool get supportsMdns => !kIsWeb;
