import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double unit = 4.0;

  // Spacing Scale
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xl2 = 24.0;
  static const double xl3 = 32.0;
  static const double xl4 = 40.0;

  // Radius Scale
  static const double radiusXs = 8.0;
  static const double radiusSm = 14.0; // Controls & Inputs
  static const double radiusMd = 20.0; // Cards & Containers
  static const double radiusLg = 28.0; // Sheets & Dialogs
  static const double radiusXl = 36.0;
  static const double radiusFull = 999.0;

  // Semantic Roles
  static const double controlRadius = radiusSm;
  static const double cardRadius = radiusMd;
  static const double dialogRadius = radiusLg;
  static const double pillRadius = radiusFull;
  static const double screenHorizontal = xl;
  static const double sectionGap = lg;
  static const double contentGap = md;
  static const double controlGap = sm;

  // Pre-built BorderRadius
  static final BorderRadius borderRadiusXs = BorderRadius.circular(radiusXs);
  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);
  static final BorderRadius borderRadiusFull = BorderRadius.circular(
    radiusFull,
  );

  // Touch Targets & Icons
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;

  static const double buttonHeightSm = 38.0;
  static const double buttonHeightMd = 50.0;
  static const double buttonHeightLg = 56.0;

  // Padding
  static const EdgeInsets cardPadding = EdgeInsets.all(18.0);
  static const EdgeInsets cardPaddingMd = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(22.0);
  static const EdgeInsets cardPaddingXl = EdgeInsets.all(28.0);
  static const EdgeInsets screenPadding = EdgeInsets.all(18.0);
  static const EdgeInsets screenHorizontalPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
  );

  // App Bar
  static const double appBarExpandedHeight = 110.0;
  static const EdgeInsets appBarTitlePadding = EdgeInsets.only(
    left: 20,
    bottom: 24,
  );
}
