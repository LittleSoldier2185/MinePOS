import 'package:flutter/widgets.dart';

/// Shared width breakpoints so every screen branches layout the same way.
abstract final class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
}

abstract final class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < Breakpoints.mobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= Breakpoints.mobile && width < Breakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= Breakpoints.tablet;
}
