import 'package:flutter/material.dart';

class AppSpacing {
  // Base unit: 4px
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

  // --- Radius (The "Soft & Organic" Look) ---
  // We moved from "Squared" (8px) to "Soft" (16px+)
  static const double radiusXs = 8.0; // For tiny tags
  static const double radiusSm = 16.0; // For Buttons/Inputs
  static const double radiusMd = 24.0; // For Cards/Containers
  static const double radiusLg = 32.0; // For Modals/Dialogs
  static const double radiusXl = 40.0;
  static const double radiusFull = 999.0; // Perfect circle/pill

  // --- Canonical Semantic Roles ---
  static const double controlRadius = radiusSm;
  static const double cardRadius = radiusMd;
  static const double dialogRadius = radiusLg;
  static const double pillRadius = radiusFull;
  static const double screenHorizontal = xl;
  static const double sectionGap = lg;
  static const double contentGap = md;
  static const double controlGap = sm;

  // --- Pre-built BorderRadius (for consistency) ---
  static final BorderRadius borderRadiusXs = BorderRadius.circular(radiusXs);
  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);
  static final BorderRadius borderRadiusFull = BorderRadius.circular(
    radiusFull,
  );

  // --- Android Auto / Touch Targets ---
  static const double iconSm = 24.0;
  static const double iconMd = 32.0;
  static const double iconLg = 40.0;

  static const double buttonHeightSm = 40.0;
  static const double buttonHeightMd =
      56.0; // Taller buttons look better with round corners
  static const double buttonHeightLg = 64.0;

  static const EdgeInsets cardPadding = EdgeInsets.all(
    20.0,
  ); // More breathing room
  static const EdgeInsets cardPaddingMd = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(24.0);
  static const EdgeInsets cardPaddingXl = EdgeInsets.all(32.0);
  static const EdgeInsets screenPadding = EdgeInsets.all(20.0);
  static const EdgeInsets screenHorizontalPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
  );

  // --- Standard App Bar ---
  static const double appBarExpandedHeight = 110.0;
  static const EdgeInsets appBarTitlePadding = EdgeInsets.only(
    left: 20,
    bottom: 24,
  );
}
