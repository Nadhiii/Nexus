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
}
