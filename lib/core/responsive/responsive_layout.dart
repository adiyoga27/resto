import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet }

class ResponsiveLayout {
  final BuildContext context;

  ResponsiveLayout(this.context);

  DeviceType get deviceType {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 ? DeviceType.tablet : DeviceType.mobile;
  }

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;

  bool get isLandscape =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  bool get isPortrait =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;

  int get crossAxisCount {
    if (isTablet && isLandscape) return 4;
    if (isTablet && isPortrait) return 3;
    if (isMobile && isLandscape) return 3;
    return 2;
  }

  double get horizontalPadding {
    if (isTablet) return 32;
    if (isMobile && isLandscape) return 24;
    return 16;
  }

  bool get showSidebar => isTablet || (isMobile && isLandscape);

  double get sidebarWidth {
    if (isTablet && isLandscape) return 260;
    if (isTablet) return 240;
    return 220;
  }
}
