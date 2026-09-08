import 'package:flutter/material.dart';

/// Responsive breakpoints for mobile, tablet, desktop.
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Responsive layout helpers.
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < Breakpoints.mobile;

  static bool isTabletOrLarger(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= Breakpoints.mobile;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double heightOf(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  /// Scale a value between mobile, tablet, and desktop.
  static T value<T extends num>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final w = widthOf(context);
    if (w >= Breakpoints.tablet && desktop != null) return desktop;
    if (w >= Breakpoints.mobile && tablet != null) return tablet;
    return mobile;
  }
}

/// Extension for easier responsive checks.
extension ResponsiveContext on BuildContext {
  bool get isMobile => Responsive.isMobile(this);
  bool get isDesktop => Responsive.isDesktop(this);
}
